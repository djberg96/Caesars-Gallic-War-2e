"use strict";

document.addEventListener("DOMContentLoaded", () => {
  const dataElement = document.querySelector("#game-data");
  if (!dataElement) return;

  const gameData = JSON.parse(dataElement.textContent);
  const areas = gameData.areas;
  const csrfToken = document.querySelector("meta[name='csrf-token']")?.content;

  let state;

  const els = {
    areaLayer: document.querySelector("#area-layer"),
    boardImage: document.querySelector("#board > img"),
    pieceLayer: document.querySelector("#piece-layer"),
    log: document.querySelector("#log"),
    selection: document.querySelector("#selection"),
    areaDetail: document.querySelector("#area-detail"),
    selectedCard: document.querySelector("#selected-card"),
    romanHand: document.querySelector("#roman-hand"),
    barbarianHand: document.querySelector("#barbarian-hand")
  };
  const hitMapSize = { width: 880, height: 1020 };
  let areaHitMap = null;
  let dragState = null;
  let suppressNextPieceClick = false;
  let piecesHidden = false;

  async function newGame() {
    const mode = document.querySelector("#play-mode")?.value || "hotseat";
    try {
      const result = await postJson("/game_sessions", { mode });
      state = result.state;
      state.gameSessionId = result.game_session_id;
      normalizeLoadedState();
      render();
    } catch (error) {
      window.alert(`New game could not be created: ${error.message}`);
    }
  }

  async function dealCards() {
    try {
      await ensureGameSession();
      const result = await postJson(`/game_sessions/${state.gameSessionId}/deal`, { state });
      state = result.state;
      state.gameSessionId = result.game_session_id;
      normalizeLoadedState();
    } catch (error) {
      log(`Cards could not be dealt: ${error.message}`);
    }
    render();
  }

  function currentStrength(unit) {
    return unit.strengths[unit.step] || 0;
  }

  function areaUnits(areaId) {
    return Object.values(state.units).filter((unit) => unit.location === areaId);
  }

  function unitFaceVisibleToActivePlayer(unit) {
    return unit.owner === state.active || enemyInCombatWithActivePlayer(unit);
  }

  function hiddenBlockRegion(unit) {
    if (unit.type === "german") return "german";

    const region = areas[unit.home]?.region || areas[unit.location]?.region;
    if (region === "belgica" || region === "belgae") return "belgae";
    if (region === "aquitania") return "aquitaine";
    if (region === "germania") return "german";
    if (region === "celtae") return "celtae";
    return "unknown";
  }

  function publicUnitLabel(unit) {
    if (unitFaceVisibleToActivePlayer(unit)) return `${unit.name} ${unit.owner} ${currentStrength(unit)}`;
    if (unit.owner === "neutral") return "Neutral block, strength hidden";
    return null;
  }

  function enemyInCombatWithActivePlayer(unit) {
    if (unit.owner === "neutral" || unit.owner === state.active) return false;
    return areaUnits(unit.location).some((other) => other.owner === state.active);
  }

  function isEnemy(left, right) {
    return left !== "neutral" && right !== "neutral" && left !== right;
  }

  function setActive(player) {
    if (state.mode !== "hotseat" && player === "barbarian") {
      log("In solitaire or AI mode, the Barbarian side is controlled by the opponent system.");
      render();
      return;
    }
    state.active = player;
    state.selectedUnit = null;
    state.selectedCard = null;
    log(`${playerName(player)} player is active. Only that player's hand is visible.`);
    render();
  }

  function playerName(player) {
    return player === "roman" ? "Roman" : "Barbarian";
  }

  async function selectUnit(id) {
    const unit = state.units[id];
    if (!unitFaceVisibleToActivePlayer(unit)) {
      await selectArea(unit.location);
      return;
    }
    if (state.movement && unit.owner === state.active && !movementAreaActivated(unit.location)) {
      await activateMovementArea(unit.location);
    }
    markUnitSelected(id);
    render();
  }

  function markUnitSelected(id) {
    const unit = state.units[id];
    state.selectedUnit = id;
    state.selectedArea = unit.location;
    if (unitFaceVisibleToActivePlayer(unit)) {
      els.selection.textContent = `${unit.name}: ${unit.owner}, strength ${currentStrength(unit)}, ${unit.initiative}${unit.fire}, in ${areaName(unit.location)}.`;
    } else {
      els.selection.textContent = `Hidden block in ${areaName(unit.location)}.`;
    }
  }

  async function selectArea(id) {
    state.selectedArea = id;
    state.selectedUnit = null;
    describeArea(id);
    if (state.movement) await activateMovementArea(id);
    render();
  }

  function areaName(id) {
    return areas[id]?.name || id;
  }

  function describeArea(id) {
    const area = areas[id];
    const units = areaUnits(id);
    const visibleLabels = units.map(publicUnitLabel).filter(Boolean);
    const hiddenEnemies = units.filter((unit) => unit.owner !== state.active && unit.owner !== "neutral").length;
    const hiddenText = hiddenEnemies ? `${hiddenEnemies} enemy block${hiddenEnemies === 1 ? "" : "s"}` : null;
    const unitText = [...visibleLabels, hiddenText].filter(Boolean).join(", ") || "No visible units";
    els.selection.textContent = area.name;
    els.areaDetail.textContent = `${area.region || "sea"}${area.port ? ", port" : ""}${area.fort ? `, fort ${area.fort.level}` : ""}. ${unitText}.`;
  }

  function canMove(unit, target) {
    return Boolean(movePlan(unit, target));
  }

  function movePlan(unit, target) {
    if (!areas[target] || areas[target].sea) return null;
    if (unit.location === "offboard" || unit.location === "eliminated") return null;
    if (!legalAreaForUnit(unit, target)) return null;
    if (!canUnitMoveThisCard(unit)) return null;

    const directBorder = borderType(unit.location, target);
    if (directBorder) return { force: false, via: null, border: directBorder };

    const forceRoute = forceMarchRoute(unit, target);
    if (forceRoute) return { force: true, via: forceRoute };

    return null;
  }

  function canUnitMoveThisCard(unit) {
    if (!state.movement) return true;
    state.movement.units ||= {};
    const moved = state.movement.units[unit.id];
    if (!moved) return movementAreaActivated(unit.location);
    if (moved.stopped || moved.steps >= 2) return false;
    return unit.owner === "roman" && unit.type === "roman" && state.supply > 0;
  }

  function forceMarchRoute(unit, target) {
    if (unit.owner !== "roman" || unit.type !== "roman" || state.supply <= 0) return null;
    if (state.movement) state.movement.units ||= {};
    if (state.movement?.units[unit.id]?.steps) return null;

    const from = unit.location;
    return areas[from].links.find((middle) => {
      if (middle === target) return false;
      const middleArea = areas[middle];
      if (!middleArea || middleArea.sea || !middleArea.links.includes(target)) return false;
      const blockers = areaUnits(middle).some((other) => isEnemy(other.owner, unit.owner) || other.owner === "neutral");
      return !blockers;
    }) || null;
  }

  function borderType(from, target) {
    return areas[from]?.borders?.[target] || (areas[from]?.links.includes(target) ? "regular" : null);
  }

  function restrictedBorder(type) {
    return type && type !== "regular";
  }

  function legalAreaForUnit(unit, target) {
    if (target === "roman_off_map") return unit.type === "roman";
    if (target === "germania") return unit.type === "roman" || unit.type === "german";
    return true;
  }

  function moveSelectedTo(target) {
    if (!state.selectedUnit) {
      selectArea(target);
      return;
    }

    moveUnitTo(state.selectedUnit, target);
  }

  async function moveUnitTo(unitId, target) {
    const unit = state.units[unitId];
    if (unit.owner !== state.active) {
      log(`${unit.name} is not controlled by the active player.`);
      render();
      return;
    }

    if (state.movement && !movementAreaActivated(unit.location)) {
      log(`Activate ${areaName(unit.location)} for movement before moving ${unit.name}.`);
      render();
      return;
    }

    const plan = movePlan(unit, target);
    if (!plan) {
      log(`${unit.name} cannot move from ${areaName(unit.location)} to ${areaName(target)}.`);
      render();
      return;
    }

    saveUndoMove(unit, target);
    try {
      await ensureGameSession();
      const result = await postJson(`/game_sessions/${state.gameSessionId}/move`, {
        state,
        unit_id: unitId,
        target
      });
      state = result.state;
      state.gameSessionId = result.game_session_id;
      normalizeLoadedState();
    } catch (error) {
      state.undoStack?.pop();
      log(error.message);
    }
    render();
  }

  function saveUndoMove(unit, target) {
    if (state.diceRolledThisTurn) return;
    state.undoStack ||= [];
    state.undoStack.push({
      kind: "move",
      unitId: unit.id,
      from: unit.location,
      to: target,
      units: structuredClone(state.units),
      supply: state.supply,
      movement: structuredClone(state.movement),
      selectedUnit: state.selectedUnit,
      selectedArea: state.selectedArea
    });
  }

  async function undoMove() {
    try {
      await ensureGameSession();
      const result = await postJson(`/game_sessions/${state.gameSessionId}/undo_move`, { state });
      state = result.state;
      state.gameSessionId = result.game_session_id;
      normalizeLoadedState();
    } catch (error) {
      log(error.message);
    }
    render();
  }

  function recordUnitMovement(unit, from, target, plan) {
    if (!state.movement) return;
    state.movement.units ||= {};

    state.movement.units[unit.id] ||= {
      origin: from,
      steps: 0,
      stopped: false
    };
    const moved = state.movement.units[unit.id];

    if (plan.force) {
      moved.steps = 2;
      moved.stopped = true;
      state.supply -= 1;
      return;
    }

    moved.steps += 1;
    if (unit.type !== "roman" || unit.owner !== "roman" || restrictedBorder(plan.border) || areaHasStopper(target, unit.owner) || moved.steps >= 2) {
      moved.stopped = true;
    }
    if (moved.steps === 2) state.supply -= 1;
  }

  function areaHasStopper(areaId, owner) {
    return areaUnits(areaId).some((unit) => isEnemy(unit.owner, owner) || unit.owner === "neutral");
  }

  async function playAction(action) {
    if (state.movement) {
      log("End the current movement action before choosing another card action.");
      render();
      return;
    }

    state.currentAction = action;
    const card = actionCard();
    if (!card) {
      log(state.mode === "hotseat" ? "Select and commit a card first." : "Select a Roman card first.");
      render();
      return;
    }

    if (action === "supply") {
      if (await performCardAction("supply_action")) await discardSelectedCard();
    } else if (action === "activate") {
      if (await performCardAction("activate_neutral")) await discardSelectedCard();
    } else if (action === "political") {
      if (!state.selectedArea) {
        log("Select a target area before a political action.");
      } else {
        if (await performCardAction("political_action", { area_id: state.selectedArea })) await discardSelectedCard();
      }
    } else if (action === "event") {
      if (await performCardAction("event_action", { area_id: state.selectedArea })) await discardSelectedCard();
    } else {
      await startMovement();
    }
    render();
  }

  function actionCard() {
    if (state.mode === "hotseat") return state.revealed ? state.committed[state.active] : state.selectedCard;
    return state.active === "roman" ? state.selectedCard : null;
  }

  function activateArea(areaId, owner) {
    if (owner === "roman" && (areaId === "germania" || areas[areaId]?.region === "britannia")) {
      log("Romans may not use neutral activation in Britannia or Germania.");
      return;
    }

    areaUnits(areaId).filter((unit) => unit.owner === "neutral").forEach((unit) => {
      unit.owner = owner;
      unit.step = 0;
    });
    log(`${playerName(owner)} activates ${areaName(areaId)}.`);
  }

  async function performCardAction(endpoint, extra = {}) {
    try {
      await ensureGameSession();
      const result = await postJson(`/game_sessions/${state.gameSessionId}/${endpoint}`, { state, ...extra });
      state = result.state;
      state.gameSessionId = result.game_session_id;
      normalizeLoadedState();
      return true;
    } catch (error) {
      log(error.message);
      return false;
    }
  }

  async function startMovement() {
    try {
      await ensureGameSession();
      const result = await postJson(`/game_sessions/${state.gameSessionId}/start_movement`, { state });
      state = result.state;
      state.gameSessionId = result.game_session_id;
      normalizeLoadedState();
    } catch (error) {
      log(error.message);
    }
  }

  function movementAreaActivated(areaId) {
    return state.movement?.areas.includes(areaId);
  }

  async function activateMovementArea(areaId) {
    if (!state.movement) return false;
    if (movementAreaActivated(areaId)) return true;
    try {
      await ensureGameSession();
      const result = await postJson(`/game_sessions/${state.gameSessionId}/activate_movement_area`, { state, area_id: areaId });
      state = result.state;
      state.gameSessionId = result.game_session_id;
      normalizeLoadedState();
      return true;
    } catch (error) {
      log(error.message);
      return false;
    }
  }

  async function completeMovementAction() {
    if (!state.movement) {
      log("No movement action is in progress.");
      render();
      return;
    }

    const movedFrom = state.movement.areas.map(areaName).join(", ") || "no areas";
    log(`Movement action finished after activating ${movedFrom}.`);
    state.movement = null;
    await discardSelectedCard();
    render();
  }

  function politicalAction(areaId, card) {
    const area = areas[areaId];
    if (!area || !area.region || area.region === "roman" || area.region === "germania") {
      log("That area is not a valid political target.");
      return;
    }

    const roll = d6();
    let modified = roll;
    if (card.area === areaId) modified -= 1;
    if (areaUnits(areaId).some((unit) => unit.owner !== state.active && unit.owner !== "neutral")) modified += 1;

    if (modified <= card.ap) {
      areaUnits(areaId).forEach((unit) => {
        if (unit.type !== "roman" && unit.type !== "german") {
          unit.owner = state.active;
          unit.location = unit.home;
        }
      });
      log(`Political action succeeds in ${area.name}: rolled ${roll}, modified ${modified}, AP ${card.ap}.`);
    } else {
      log(`Political action fails in ${area.name}: rolled ${roll}, modified ${modified}, AP ${card.ap}.`);
    }
  }

  function eventAction(card) {
    if (card.title === "Baggage Train") {
      if (state.active === "roman") state.supply = Math.min(19, state.supply + 5);
      else state.supply = Math.max(0, state.supply - 2);
      log(`${playerName(state.active)} resolves Baggage Train.`);
      return;
    }

    if (!state.selectedArea) {
      log("Select an area, then play the revolt event.");
      return;
    }

    const count = card.title === "Massive Revolt" ? 3 : card.title === "Major Revolt" ? 2 : 1;
    activateArea(state.selectedArea, state.active === "roman" ? "roman" : "barbarian");
    if (card.title === "Massive Revolt" && state.active === "barbarian") {
      const v = state.units.vercingetorix;
      v.location = state.selectedArea;
      v.owner = "barbarian";
    }
    log(`${card.title} resolved for ${areaName(state.selectedArea)}. Apply up to ${count} selected areas manually if needed.`);
  }

  async function discardSelectedCard() {
    const played = actionCard();
    if (!played) return;

    try {
      await ensureGameSession();
      const result = await postJson(`/game_sessions/${state.gameSessionId}/discard_card`, {
        state,
        player: state.active
      });
      state = result.state;
      state.gameSessionId = result.game_session_id;
      normalizeLoadedState();
    } catch (error) {
      log(error.message);
      return;
    }

    if (state.mode !== "hotseat") {
      await drawBotCard();
    }
  }

  async function commitCard() {
    if (state.mode !== "hotseat") {
      log("Face-down simultaneous commit is only used in hotseat mode. In solitaire mode, play a Roman card, then draw the bot card.");
      render();
      return;
    }
    if (state.revealed) {
      log("Resolve the revealed cards before committing new cards.");
      render();
      return;
    }
    if (!state.selectedCard) {
      log("Select a card from your hand before committing.");
      render();
      return;
    }
    try {
      await ensureGameSession();
      const result = await postJson(`/game_sessions/${state.gameSessionId}/commit_card`, {
        state,
        player: state.active,
        card_id: state.selectedCard.id
      });
      state = result.state;
      state.gameSessionId = result.game_session_id;
      normalizeLoadedState();
    } catch (error) {
      log(error.message);
    }
    render();
  }

  async function revealCards() {
    if (state.mode !== "hotseat") {
      log("Reveal is only used in hotseat mode.");
      render();
      return;
    }
    if (!state.committed.roman || !state.committed.barbarian) {
      log("Both players must commit a card before reveal.");
      render();
      return;
    }
    try {
      await ensureGameSession();
      const result = await postJson(`/game_sessions/${state.gameSessionId}/reveal_cards`, { state });
      state = result.state;
      state.gameSessionId = result.game_session_id;
      normalizeLoadedState();
    } catch (error) {
      log(error.message);
    }
    render();
  }

  async function drawBotCard() {
    try {
      await ensureGameSession();
      const result = await postJson(`/game_sessions/${state.gameSessionId}/draw_bot_card`, { state });
      state = result.state;
      state.gameSessionId = result.game_session_id;
      normalizeLoadedState();
    } catch (error) {
      log(error.message);
    }
    render();
  }

  function resolveBotCard(card) {
    if (card.area && isNeutralArea(card.area) && state.botNeutralActivations < 2) {
      activateArea(card.area, "barbarian");
      state.botNeutralActivations += 1;
      return;
    }

    if (card.area && (isNeutralArea(card.area) || isRomanControlledArea(card.area))) {
      botPoliticalAction(card.area, card);
      return;
    }

    if (card.area && botMoveFrom(card.area)) return;

    resolveBotEvent(card);
  }

  function isNeutralArea(areaId) {
    return areaUnits(areaId).some((unit) => unit.owner === "neutral");
  }

  function isRomanControlledArea(areaId) {
    return areaUnits(areaId).some((unit) => unit.owner === "roman" && unit.type !== "roman");
  }

  function botPoliticalAction(areaId, card) {
    const area = areas[areaId];
    if (!area || area.region === "roman" || area.region === "germania") {
      log("Bot political action had no valid target.");
      return;
    }

    const roll = d6();
    if (roll === 1 || roll <= card.ap) {
      areaUnits(areaId).forEach((unit) => {
        if (unit.type !== "roman" && unit.type !== "german") unit.owner = "barbarian";
      });
      log(`Bot political action succeeds in ${areaName(areaId)} on roll ${roll}.`);
    } else {
      log(`Bot political action fails in ${areaName(areaId)} on roll ${roll}.`);
    }
  }

  function botMoveFrom(areaId) {
    const attackers = areaUnits(areaId).filter((unit) => unit.owner === "barbarian" && currentStrength(unit) >= 1);
    if (!attackers.length) return false;

    const targets = areas[areaId].links.filter((target) => !areas[target]?.sea && areaUnits(target).filter((unit) => unit.owner !== "barbarian").length === 1);
    const target = targets.find(isRomanControlledArea) || targets[0];
    if (!target) return false;

    attackers.slice(0, 2).forEach((unit) => {
      unit.location = target;
    });
    log(`Bot moves ${attackers.slice(0, 2).map((unit) => unit.name).join(", ")} from ${areaName(areaId)} to ${areaName(target)}.`);
    resolveBattles();
    return true;
  }

  function resolveBotEvent(card) {
    if (card.title === "Baggage Train") {
      if (botMoveFrom("germania")) return;
      state.supply = Math.max(0, state.supply - 2);
      log("Bot Baggage Train reduces Roman supply by 2.");
      return;
    }

    const target = randomBotTarget();
    if (!target) {
      log(`Bot ${card.title} found no valid revolt target.`);
      return;
    }

    activateArea(target, "barbarian");
    if (card.title === "Massive Revolt" && state.turn >= 5) {
      const v = state.units.vercingetorix;
      v.location = target;
      v.owner = "barbarian";
      log(`Vercingetorix enters at ${areaName(target)}.`);
    }
    botMoveFrom(target);
  }

  function randomBotTarget() {
    const candidates = Object.keys(areas).filter((areaId) => {
      const area = areas[areaId];
      return area.region && area.region !== "roman" && area.region !== "germania" && (isNeutralArea(areaId) || isRomanControlledArea(areaId));
    });
    return candidates[Math.floor(Math.random() * candidates.length)];
  }

  function contestedAreas() {
    return Object.keys(areas).filter((areaId) => {
      const owners = new Set(areaUnits(areaId).map((unit) => unit.owner).filter((owner) => owner !== "neutral"));
      return owners.has("roman") && owners.has("barbarian");
    });
  }

  async function resolveBattles() {
    try {
      await ensureGameSession();
      const result = await postJson(`/game_sessions/${state.gameSessionId}/resolve_battles`, { state });
      state = result.state;
      state.gameSessionId = result.game_session_id;
      normalizeLoadedState();
    } catch (error) {
      log(error.message);
    }
    render();
  }

  function resolveBattle(areaId) {
    const maxRounds = areaId === "germania" ? 2 : 3;
    log(`Battle begins in ${areaName(areaId)}.`);

    for (let round = 1; round <= maxRounds; round += 1) {
      const fighters = areaUnits(areaId).filter((unit) => unit.owner === "roman" || unit.owner === "barbarian");
      if (!hasBothSides(fighters)) break;

      fighters.sort((left, right) => initiativeValue(left) - initiativeValue(right)).forEach((unit) => {
        if (unit.location !== areaId || currentStrength(unit) <= 0) return;

        const enemies = areaUnits(areaId).filter((other) => isEnemy(other.owner, unit.owner));
        if (!enemies.length) return;

        const rolls = Array.from({ length: currentStrength(unit) }, d6);
        const hits = rolls.filter((roll) => roll <= unit.fire).length;
        if (hits) applyHits(enemies, hits);
        log(`${unit.name} fires ${rolls.join(", ")} for ${hits} hit${hits === 1 ? "" : "s"}.`);
      });
      eliminateDead(areaId);
    }

    const survivors = areaUnits(areaId).filter((unit) => unit.owner === "roman" || unit.owner === "barbarian");
    if (hasBothSides(survivors)) {
      log(`Battle in ${areaName(areaId)} is unresolved after ${maxRounds} rounds. Move retreats manually.`);
    } else if (survivors[0]) {
      log(`${playerName(survivors[0].owner)} controls ${areaName(areaId)} after battle.`);
    }
  }

  function initiativeValue(unit) {
    if (unit.id === "legion_x") return 0;
    return { A: 1, B: 2, C: 3, D: 4 }[unit.initiative] || 5;
  }

  function hasBothSides(units) {
    const owners = new Set(units.map((unit) => unit.owner));
    return owners.has("roman") && owners.has("barbarian");
  }

  function applyHits(enemies, hits) {
    for (let i = 0; i < hits; i += 1) {
      const target = enemies
        .filter((unit) => unit.location !== "eliminated")
        .sort((left, right) => currentStrength(right) - currentStrength(left))[0];
      if (!target) return;
      target.step += 1;
    }
  }

  function eliminateDead(areaId) {
    areaUnits(areaId).forEach((unit) => {
      if (currentStrength(unit) > 0) return;

      unit.location = "eliminated";
      if (unit.id === "legion_x") {
        log("Caesar has been killed. Barbarian instant victory.");
      } else if (unit.type === "roman") {
        state.vp = Math.max(0, state.vp - 5);
        log(`${unit.name} eliminated. Roman VP -5.`);
      } else if (unit.type === "german") {
        state.vp += unit.id === "ariovistus" ? 2 : 1;
        log(`${unit.name} eliminated. Roman VP increases.`);
      } else if (unit.id === "vercingetorix") {
        state.vp += 3;
        log("Vercingetorix eliminated. Roman VP +3.");
      } else {
        log(`${unit.name} eliminated.`);
      }
    });
  }

  async function endTurn() {
    if (state.movement) {
      await completeMovementAction();
      return;
    }

    try {
      await ensureGameSession();
      const result = await postJson(`/game_sessions/${state.gameSessionId}/end_turn`, { state });
      state = result.state;
      state.gameSessionId = result.game_session_id;
      normalizeLoadedState();
    } catch (error) {
      log(`Turn could not be ended: ${error.message}`);
    }
    render();
  }

  function d6() {
    state.diceRolledThisTurn = true;
    state.undoStack = [];
    return Math.floor(Math.random() * 6) + 1;
  }

  function log(message) {
    if (!state) return;
    state.log.unshift(message);
    if (state.log.length > 80) state.log.length = 80;
  }

  function render() {
    renderStatus();
    renderAreas();
    renderPieces();
    renderHands();
    renderLog();
    renderModeHelp();
    renderActionButtons();
    renderUndoButton();
    renderPieceToggle();
    document.querySelectorAll(".player-button").forEach((button) => {
      button.classList.toggle("is-active", button.dataset.player === state.active);
    });
    els.selectedCard.textContent = state.selectedCard ? `${state.selectedCard.title}, AP ${state.selectedCard.ap}.` : "No card selected.";
    renderCommittedCards();
  }

  function renderStatus() {
    document.querySelector("#mode-label").textContent = modeName();
    document.querySelector("#play-mode").value = state.mode;
    document.querySelector("#turn-label").textContent = gameData.years[state.turn];
    document.querySelector("#phase-label").textContent = state.phase;
    document.querySelector("#active-label").textContent = playerName(state.active);
    document.querySelector("#supply-label").textContent = `Supply ${state.supply}`;
    document.querySelector("#vp-label").textContent = `VP ${state.vp}`;
  }

  function modeName() {
    if (state.mode === "solitaire") return "Solitaire";
    if (state.mode === "ai") return "AI Opponent";
    return "Hotseat";
  }

  function renderAreas() {
    els.areaLayer.innerHTML = "";

    const clickCatcher = document.createElementNS("http://www.w3.org/2000/svg", "rect");
    clickCatcher.setAttribute("x", 0);
    clickCatcher.setAttribute("y", 0);
    clickCatcher.setAttribute("width", 100);
    clickCatcher.setAttribute("height", 100);
    clickCatcher.classList.add("area-click-catcher");
    clickCatcher.addEventListener("click", (event) => {
      const areaId = areaFromMapClick(event);
      if (areaId) moveSelectedTo(areaId);
    });
    els.areaLayer.append(clickCatcher);

    Object.values(areas).forEach((area) => {
      if (area.sea) return;

      const marker = document.createElementNS("http://www.w3.org/2000/svg", "rect");
      marker.setAttribute("x", area.x - 4);
      marker.setAttribute("y", area.y - 3);
      marker.setAttribute("width", 8);
      marker.setAttribute("height", 6);
      marker.setAttribute("rx", 1);
      marker.classList.add("area-hotspot");
      marker.classList.toggle("is-selected", state.selectedArea === area.id);
      marker.classList.toggle("is-movement", movementAreaActivated(area.id));
      marker.classList.toggle("is-drag-target", state.dragArea === area.id);
      els.areaLayer.append(marker);
    });
  }

  function areaFromMapClick(event) {
    return areaFromClientPoint(event.clientX, event.clientY);
  }

  function areaFromClientPoint(clientX, clientY) {
    const point = mapClientPoint(clientX, clientY);
    if (!point) return null;
    if (!areaHitMap) return nearestArea(point.x, point.y);

    const x = Math.round((point.x / 100) * (areaHitMap.width - 1));
    const y = Math.round((point.y / 100) * (areaHitMap.height - 1));
    const index = nearestOpenHitPixel(x, y);
    if (index === null) return nearestArea(point.x, point.y);

    const componentId = areaHitMap.labels[index];
    const seeds = areaHitMap.componentSeeds.get(componentId) || [];
    if (!seeds.length) return nearestArea(point.x, point.y);

    const lowX = index % areaHitMap.width;
    const lowY = Math.floor(index / areaHitMap.width);
    return seeds.sort((left, right) => distance2(left, lowX, lowY) - distance2(right, lowX, lowY))[0].areaId;
  }

  function mapClientPoint(clientX, clientY) {
    const bounds = els.areaLayer.getBoundingClientRect();
    if (!bounds.width || !bounds.height) return null;
    return {
      x: ((clientX - bounds.left) / bounds.width) * 100,
      y: ((clientY - bounds.top) / bounds.height) * 100
    };
  }

  function nearestArea(x, y) {
    return Object.values(areas)
      .filter((area) => !area.sea)
      .sort((left, right) => ((left.x - x) ** 2) + ((left.y - y) ** 2) - ((right.x - x) ** 2) - ((right.y - y) ** 2))[0]?.id;
  }

  function nearestOpenHitPixel(x, y) {
    const direct = hitIndex(x, y);
    if (direct !== null && areaHitMap.labels[direct] >= 0) return direct;

    for (let radius = 1; radius <= 12; radius += 1) {
      for (let dy = -radius; dy <= radius; dy += 1) {
        for (let dx = -radius; dx <= radius; dx += 1) {
          if (Math.abs(dx) !== radius && Math.abs(dy) !== radius) continue;
          const index = hitIndex(x + dx, y + dy);
          if (index !== null && areaHitMap.labels[index] >= 0) return index;
        }
      }
    }
    return null;
  }

  function hitIndex(x, y) {
    if (!areaHitMap || x < 0 || y < 0 || x >= areaHitMap.width || y >= areaHitMap.height) return null;
    return y * areaHitMap.width + x;
  }

  function distance2(seed, x, y) {
    return ((seed.x - x) ** 2) + ((seed.y - y) ** 2);
  }

  function prepareAreaHitMap() {
    if (!els.boardImage) return;
    if (!els.boardImage.complete) {
      els.boardImage.addEventListener("load", prepareAreaHitMap, { once: true });
      return;
    }

    const canvas = document.createElement("canvas");
    canvas.width = hitMapSize.width;
    canvas.height = hitMapSize.height;
    const context = canvas.getContext("2d", { willReadFrequently: true });
    context.drawImage(els.boardImage, 0, 0, canvas.width, canvas.height);

    const pixels = context.getImageData(0, 0, canvas.width, canvas.height).data;
    const labels = new Int32Array(canvas.width * canvas.height);
    labels.fill(-2);

    for (let index = 0; index < labels.length; index += 1) {
      const pixelIndex = index * 4;
      if (isBorderPixel(pixels[pixelIndex], pixels[pixelIndex + 1], pixels[pixelIndex + 2])) labels[index] = -1;
    }

    let componentId = 0;
    const queue = new Int32Array(labels.length);
    for (let index = 0; index < labels.length; index += 1) {
      if (labels[index] !== -2) continue;
      floodFillHitComponent(index, componentId, labels, queue, canvas.width, canvas.height);
      componentId += 1;
    }

    const componentSeeds = new Map();
    Object.values(areas).filter((area) => !area.sea).forEach((area) => {
      const x = Math.round((area.x / 100) * (canvas.width - 1));
      const y = Math.round((area.y / 100) * (canvas.height - 1));
      const index = nearestLabeledHitPixel(labels, canvas.width, canvas.height, x, y);
      if (index === null) return;

      const seedComponent = labels[index];
      if (seedComponent < 0) return;
      if (!componentSeeds.has(seedComponent)) componentSeeds.set(seedComponent, []);
      componentSeeds.get(seedComponent).push({ areaId: area.id, x: index % canvas.width, y: Math.floor(index / canvas.width) });
    });

    areaHitMap = { width: canvas.width, height: canvas.height, labels, componentSeeds };
  }

  function isBorderPixel(red, green, blue) {
    const average = (red + green + blue) / 3;
    const whiteLine = red > 225 && green > 220 && blue > 205 && (red - blue) < 55;
    return average < 72 || whiteLine;
  }

  function floodFillHitComponent(start, componentId, labels, queue, width, height) {
    let head = 0;
    let tail = 0;
    labels[start] = componentId;
    queue[tail] = start;
    tail += 1;

    while (head < tail) {
      const index = queue[head];
      head += 1;
      const x = index % width;
      const y = Math.floor(index / width);

      if (x > 0) tail = enqueueHitNeighbor(index - 1, componentId, labels, queue, tail);
      if (x < width - 1) tail = enqueueHitNeighbor(index + 1, componentId, labels, queue, tail);
      if (y > 0) tail = enqueueHitNeighbor(index - width, componentId, labels, queue, tail);
      if (y < height - 1) tail = enqueueHitNeighbor(index + width, componentId, labels, queue, tail);
    }
  }

  function enqueueHitNeighbor(index, componentId, labels, queue, tail) {
    if (labels[index] !== -2) return tail;
    labels[index] = componentId;
    queue[tail] = index;
    return tail + 1;
  }

  function nearestLabeledHitPixel(labels, width, height, x, y) {
    const direct = y * width + x;
    if (labels[direct] >= 0) return direct;

    for (let radius = 1; radius <= 24; radius += 1) {
      for (let dy = -radius; dy <= radius; dy += 1) {
        for (let dx = -radius; dx <= radius; dx += 1) {
          if (Math.abs(dx) !== radius && Math.abs(dy) !== radius) continue;
          const nextX = x + dx;
          const nextY = y + dy;
          if (nextX < 0 || nextY < 0 || nextX >= width || nextY >= height) continue;
          const index = nextY * width + nextX;
          if (labels[index] >= 0) return index;
        }
      }
    }
    return null;
  }

  function renderPieces() {
    els.pieceLayer.innerHTML = "";
    if (piecesHidden) return;

    const byArea = {};
    Object.values(state.units).forEach((unit) => {
      if (!areas[unit.location]) return;
      byArea[unit.location] ||= [];
      byArea[unit.location].push(unit);
    });

    Object.entries(byArea).forEach(([areaId, units]) => {
      const area = areas[areaId];
      units.forEach((unit, index) => {
        const offsetX = ((index % 4) - 1.5) * 1.8;
        const offsetY = (Math.floor(index / 4) - 0.5) * 2.2;
        const piece = document.createElement("button");
        piece.className = `piece owner-${unit.owner}`;
        const faceVisible = unitFaceVisibleToActivePlayer(unit);
        piece.classList.toggle("is-selected", state.selectedUnit === unit.id);
        piece.classList.toggle("is-hidden", !faceVisible);
        if (!faceVisible) piece.classList.add(`hidden-region-${hiddenBlockRegion(unit)}`);
        piece.style.left = `${area.x + offsetX}%`;
        piece.style.top = `${area.y + offsetY}%`;
        piece.title = faceVisible ? `${unit.name} ${unit.owner} strength ${currentStrength(unit)}` : "Hidden block";
        piece.innerHTML = `<img src="${unit.image}" alt="${faceVisible ? unit.name : "Hidden block"}">${faceVisible ? `<span class="strength-badge">${currentStrength(unit)}</span>` : ""}`;
        piece.addEventListener("click", (event) => {
          event.stopPropagation();
          if (suppressNextPieceClick) {
            suppressNextPieceClick = false;
            return;
          }
          selectUnit(unit.id);
        });
        piece.addEventListener("pointerdown", (event) => beginPieceDrag(event, unit.id));
        els.pieceLayer.append(piece);
      });
    });
  }

  async function beginPieceDrag(event, unitId) {
    if (event.button !== 0) return;
    const unit = state.units[unitId];
    if (unit.owner !== state.active) return;

    event.preventDefault();
    event.stopPropagation();
    event.currentTarget.setPointerCapture(event.pointerId);
    if (state.movement && unit.owner === state.active && !movementAreaActivated(unit.location)) {
      const activated = await activateMovementArea(unit.location);
      if (!activated) {
        event.currentTarget.releasePointerCapture(event.pointerId);
        render();
        return;
      }
    }
    markUnitSelected(unitId);
    renderAreas();
    dragState = {
      unitId,
      pointerId: event.pointerId,
      startX: event.clientX,
      startY: event.clientY,
      dragged: false,
      ghost: createDragGhost(event.currentTarget, event.clientX, event.clientY)
    };
    event.currentTarget.classList.add("is-dragging");
    event.currentTarget.addEventListener("pointermove", updatePieceDrag);
    event.currentTarget.addEventListener("pointerup", endPieceDrag);
    event.currentTarget.addEventListener("pointercancel", cancelPieceDrag);
  }

  function updatePieceDrag(event) {
    if (!dragState || event.pointerId !== dragState.pointerId) return;
    const distance = Math.hypot(event.clientX - dragState.startX, event.clientY - dragState.startY);
    if (distance > 4) dragState.dragged = true;
    moveDragGhost(event.clientX, event.clientY);
    if (!dragState.dragged) return;

    const areaId = areaFromClientPoint(event.clientX, event.clientY);
    if (state.dragArea !== areaId) {
      state.dragArea = areaId;
      renderAreas();
    }
  }

  function endPieceDrag(event) {
    if (!dragState || event.pointerId !== dragState.pointerId) return;
    const target = state.dragArea || areaFromClientPoint(event.clientX, event.clientY);
    const dragged = dragState.dragged;
    const unitId = dragState.unitId;
    cleanupPieceDrag(event.currentTarget);
    if (dragged) suppressNextPieceClick = true;
    if (dragged && target) {
      moveUnitTo(unitId, target);
    } else {
      renderAreas();
    }
    dragState = null;
  }

  function cancelPieceDrag(event) {
    if (!dragState || event.pointerId !== dragState.pointerId) return;
    cleanupPieceDrag(event.currentTarget);
    dragState = null;
    renderAreas();
  }

  function cleanupPieceDrag(piece) {
    if (dragState && piece.hasPointerCapture?.(dragState.pointerId)) piece.releasePointerCapture(dragState.pointerId);
    dragState?.ghost?.remove();
    piece.classList.remove("is-dragging");
    piece.removeEventListener("pointermove", updatePieceDrag);
    piece.removeEventListener("pointerup", endPieceDrag);
    piece.removeEventListener("pointercancel", cancelPieceDrag);
    state.dragArea = null;
  }

  function createDragGhost(piece, clientX, clientY) {
    const ghost = piece.cloneNode(true);
    const bounds = piece.getBoundingClientRect();
    ghost.classList.add("piece-drag-ghost");
    ghost.style.width = `${bounds.width}px`;
    ghost.style.height = `${bounds.height}px`;
    document.body.append(ghost);
    moveDragGhost(clientX, clientY, ghost);
    return ghost;
  }

  function moveDragGhost(clientX, clientY, ghost = dragState?.ghost) {
    if (!ghost) return;
    ghost.style.left = `${clientX}px`;
    ghost.style.top = `${clientY}px`;
  }

  function renderHands() {
    renderHand("roman", els.romanHand);
    renderHand("barbarian", els.barbarianHand);
  }

  function renderHand(player, container) {
    container.innerHTML = "";
    state.hands[player].forEach((card) => {
      const button = document.createElement("button");
      const currentPlayer = player === state.active;
      const committed = state.committed[player]?.id === card.id;
      const hidden = state.mode === "hotseat" && !currentPlayer;
      button.className = `card${hidden ? " is-hidden" : ""}`;
      button.disabled = hidden || Boolean(state.movement) || (state.mode === "hotseat" && (state.revealed || committed));
      button.classList.toggle("is-active", currentPlayer && state.selectedCard?.id === card.id);
      if (hidden) {
        button.innerHTML = "<span>Hidden card</span>";
      } else if (committed) {
        button.innerHTML = "<strong>Committed</strong><small>Face down</small>";
      } else {
        button.innerHTML = `<strong>${card.title}</strong><small>AP ${card.ap} ${card.type}</small>`;
      }
      button.addEventListener("click", () => {
        if (player !== state.active) return;
        state.selectedCard = card;
        render();
      });
      container.append(button);
    });
    if (player === "barbarian" && state.mode !== "hotseat") {
      const marker = document.createElement("button");
      marker.className = "card is-hidden";
      marker.disabled = true;
      marker.innerHTML = state.mode === "ai" ? "<span>AI controlled</span>" : `<span>Bot deck: ${state.botDeck.length}</span>`;
      container.append(marker);
    }
  }

  function renderCommittedCards() {
    const container = document.querySelector("#committed-cards");
    const line = (player) => {
      const card = state.committed[player];
      if (!card) return `${playerName(player)}: no committed card`;
      return state.revealed ? `${playerName(player)}: ${card.title}, AP ${card.ap}` : `${playerName(player)}: committed face down`;
    };
    container.innerHTML = `<div>${line("roman")}</div><div>${line("barbarian")}</div>`;
  }

  function renderModeHelp() {
    const help = document.querySelector("#mode-help");
    const commitButton = document.querySelector("#commit-card");
    const revealButton = document.querySelector("#reveal-cards");
    const botButton = document.querySelector("#bot-card");
    const barbarianButton = document.querySelector("[data-player='barbarian']");
    botButton.disabled = Boolean(state.movement);

    if (state.mode === "hotseat") {
      help.textContent = state.movement ? "Movement: move units from activated green areas, then click End Turn to finish this card play." : "Hotseat: use the Roman/Barbarian buttons to pass control. Each side commits a hidden card, then reveal both.";
      commitButton.hidden = false;
      revealButton.hidden = false;
      botButton.hidden = true;
      barbarianButton.disabled = false;
    } else if (state.mode === "solitaire") {
      help.textContent = state.movement ? "Movement: move units from activated green areas, then click End Turn to finish this card play and reveal the bot card." : "Solitaire: you play Romans. After each Roman card resolves, the bot reveals the next deck card and follows the solo priority matrix.";
      commitButton.hidden = true;
      revealButton.hidden = true;
      botButton.hidden = false;
      barbarianButton.disabled = true;
    } else {
      help.textContent = state.movement ? "Movement: move units from activated green areas, then click End Turn to finish this card play." : gameData.ai.configured ? `AI mode: local config loaded for ${gameData.ai.model || "configured model"}. AI calls are not wired yet.` : "AI mode: copy config/ai.yml.example to config/ai.yml and add a local API key. AI calls are not wired yet.";
      commitButton.hidden = true;
      revealButton.hidden = true;
      botButton.hidden = false;
      barbarianButton.disabled = true;
    }
  }

  function renderActionButtons() {
    document.querySelectorAll("[data-action]").forEach((button) => {
      button.classList.toggle("is-active", button.dataset.action === state.currentAction);
    });
  }

  function renderUndoButton() {
    const button = document.querySelector("#undo-move");
    button.disabled = state.diceRolledThisTurn || !(state.undoStack?.length);
  }

  function renderPieceToggle() {
    const button = document.querySelector("#toggle-pieces");
    button.textContent = piecesHidden ? "Show" : "Hide";
    button.setAttribute("aria-pressed", piecesHidden ? "true" : "false");
  }

  function togglePieces() {
    piecesHidden = !piecesHidden;
    render();
  }

  function renderLog() {
    els.log.innerHTML = state.log.map((entry) => `<li>${entry}</li>`).join("");
  }

  function saveGame() {
    localStorage.setItem("cgw2e-save", JSON.stringify(state));
    log("Game saved in this browser.");
    render();
  }

  function loadGame() {
    const saved = localStorage.getItem("cgw2e-save");
    if (!saved) {
      log("No saved game found.");
      render();
      return;
    }
    state = JSON.parse(saved);
    normalizeLoadedState();
    log("Saved game loaded.");
    render();
  }

  function normalizeLoadedState() {
    if (state.movement) {
      state.movement.units ||= {};
      state.movement.crossings ||= {};
    }
    state.dragArea = null;
    state.undoStack ||= [];
    state.diceRolledThisTurn ||= false;
    state.gameSessionId ||= null;
  }

  async function setMode(mode) {
    state.mode = mode;
    state.active = "roman";
    state.selectedCard = null;
    state.committed = { roman: null, barbarian: null };
    state.revealed = false;
    state.movement = null;
    state.currentAction = null;
    log(`Mode changed to ${modeName()}. Dealing a fresh hand for this mode.`);
    await dealCards();
  }

  async function changeMode(mode) {
    if (mode === state.mode) return;
    if (window.confirm("Save the current game before switching modes?")) {
      saveGame();
    }
    await setMode(mode);
  }

  function exportGame() {
    document.querySelector("#export-text").value = JSON.stringify(state, null, 2);
    document.querySelector("#export-dialog").showModal();
  }

  async function createGameSession() {
    try {
      const result = await postJson("/game_sessions", { state });
      state.gameSessionId = result.game_session_id;
    } catch (error) {
      log(`Database session was not created: ${error.message}`);
      render();
    }
  }

  async function ensureGameSession() {
    if (state.gameSessionId) return;
    await createGameSession();
    if (!state.gameSessionId) throw new Error("No database session is available.");
  }

  async function postJson(url, body) {
    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        ...(csrfToken ? { "X-CSRF-Token": csrfToken } : {})
      },
      body: JSON.stringify(body)
    });
    const payload = await response.json();
    if (!response.ok) throw new Error(payload.error || "Request failed.");
    return payload;
  }

  document.querySelector("#new-game").addEventListener("click", newGame);
  document.querySelector("#deal-cards").addEventListener("click", () => dealCards());
  document.querySelector("#commit-card").addEventListener("click", () => commitCard());
  document.querySelector("#reveal-cards").addEventListener("click", () => revealCards());
  document.querySelector("#bot-card").addEventListener("click", drawBotCard);
  document.querySelector("#play-mode").addEventListener("change", (event) => changeMode(event.target.value));
  document.querySelector("#end-turn").addEventListener("click", endTurn);
  document.querySelector("#undo-move").addEventListener("click", undoMove);
  document.querySelector("#toggle-pieces").addEventListener("click", togglePieces);
  document.querySelector("#save-game").addEventListener("click", saveGame);
  document.querySelector("#load-game").addEventListener("click", loadGame);
  document.querySelector("#export-game").addEventListener("click", exportGame);
  document.querySelector("#resolve-battles").addEventListener("click", resolveBattles);
  document.querySelectorAll(".player-button").forEach((button) => button.addEventListener("click", () => setActive(button.dataset.player)));
  document.querySelectorAll("[data-action]").forEach((button) => button.addEventListener("click", () => playAction(button.dataset.action)));

  prepareAreaHitMap();
  newGame();
});
