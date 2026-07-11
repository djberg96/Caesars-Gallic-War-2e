"use strict";

document.addEventListener("DOMContentLoaded", () => {
  const dataElement = document.querySelector("#game-data");
  if (!dataElement) return;

  const gameData = JSON.parse(dataElement.textContent);
  const areas = gameData.areas;
  const specs = gameData.units;

  let state;

  const els = {
    areaLayer: document.querySelector("#area-layer"),
    pieceLayer: document.querySelector("#piece-layer"),
    log: document.querySelector("#log"),
    selection: document.querySelector("#selection"),
    areaDetail: document.querySelector("#area-detail"),
    selectedCard: document.querySelector("#selected-card"),
    romanHand: document.querySelector("#roman-hand"),
    barbarianHand: document.querySelector("#barbarian-hand")
  };

  function makeUnit(id) {
    const spec = specs[id];
    return {
      ...spec,
      location: spec.home,
      owner: spec.type === "roman" ? "roman" : "neutral",
      step: 0
    };
  }

  function newGame() {
    const units = {};
    Object.keys(specs).forEach((id) => {
      units[id] = makeUnit(id);
    });

    gameData.variable_areas.forEach((areaId) => {
      const area = areas[areaId];
      const primary = area.tribes[0];
      const alternate = area.alternate;
      if (!alternate) return;

      if (Math.random() < 0.5) {
        units[primary].location = "offboard";
        units[alternate].location = areaId;
      } else {
        units[alternate].location = "offboard";
      }
    });

    ["helvetii", "ariovistus", "german_marcomanni", "german_tencteri", "german_usipetes"].forEach((id) => {
      units[id].owner = "barbarian";
    });
    ["volcae", "allobroges"].forEach((id) => {
      units[id].owner = "roman";
    });

    units.allobroges.step = units.allobroges.strengths.length - 1;
    units.legion_xi.step = 1;
    units.legion_xii.step = 1;

    state = {
      turn: 0,
      phase: "Card Phase",
      active: "roman",
      supply: 15,
      vp: 0,
      units,
      selectedUnit: null,
      selectedArea: null,
      selectedCard: null,
      committed: { roman: null, barbarian: null },
      revealed: false,
      mode: document.querySelector("#play-mode")?.value || "hotseat",
      botDeck: [],
      botNeutralActivations: 0,
      currentAction: "movement",
      hands: { roman: [], barbarian: [] },
      discard: [],
      log: []
    };

    log("New game set up. Variable tribes were randomly selected.");
    dealCards();
    render();
  }

  function buildDeck() {
    const areaCards = Object.values(areas)
      .filter((area) => !area.sea && area.region && area.region !== "roman")
      .map((area) => ({
        id: area.id,
        title: area.name,
        area: area.id,
        ap: area.region === "germania" ? 3 : area.region === "belgica" ? 2 : 1,
        type: "area"
      }));
    const events = ["Baggage Train", "Minor Revolt", "Minor Revolt", "Major Revolt", "Massive Revolt"].map((title, index) => ({
      id: `event_${index}_${title.toLowerCase().replaceAll(" ", "_")}`,
      title,
      ap: 1,
      type: "event"
    }));
    return shuffle(areaCards.concat(events));
  }

  function shuffle(items) {
    const copy = items.slice();
    for (let i = copy.length - 1; i > 0; i -= 1) {
      const j = Math.floor(Math.random() * (i + 1));
      [copy[i], copy[j]] = [copy[j], copy[i]];
    }
    return copy;
  }

  function dealCards() {
    const deck = buildDeck();
    const count = 5;
    state.hands.roman = deck.splice(0, count);
    if (state.mode === "hotseat") {
      state.hands.barbarian = deck.splice(0, count);
      state.botDeck = [];
    } else {
      state.hands.barbarian = [];
      state.botDeck = deck;
    }
    state.botNeutralActivations = 0;
    state.selectedCard = null;
    state.committed = { roman: null, barbarian: null };
    state.revealed = false;
    log(state.mode === "hotseat" ? `Dealt ${count} cards to each player.` : `Dealt ${count} cards to the Roman player. The opponent uses the draw deck.`);
    render();
  }

  function currentStrength(unit) {
    return unit.strengths[unit.step] || 0;
  }

  function areaUnits(areaId) {
    return Object.values(state.units).filter((unit) => unit.location === areaId);
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

  function selectUnit(id) {
    const unit = state.units[id];
    state.selectedUnit = id;
    state.selectedArea = unit.location;
    els.selection.textContent = `${unit.name}: ${unit.owner}, strength ${currentStrength(unit)}, ${unit.initiative}${unit.fire}, in ${areaName(unit.location)}.`;
    render();
  }

  function selectArea(id) {
    state.selectedArea = id;
    state.selectedUnit = null;
    describeArea(id);
    render();
  }

  function areaName(id) {
    return areas[id]?.name || id;
  }

  function describeArea(id) {
    const area = areas[id];
    const units = areaUnits(id);
    const unitText = units.length ? units.map((unit) => `${unit.name} ${unit.owner} ${currentStrength(unit)}`).join(", ") : "No units";
    els.selection.textContent = area.name;
    els.areaDetail.textContent = `${area.region || "sea"}${area.port ? ", port" : ""}${area.fort ? `, fort ${area.fort.level}` : ""}. ${unitText}.`;
  }

  function canMove(unit, target) {
    if (!areas[target] || areas[target].sea) return false;
    if (unit.location === "offboard" || unit.location === "eliminated") return false;

    const from = unit.location;
    const direct = areas[from]?.links.includes(target);
    if (direct) return legalAreaForUnit(unit, target);

    const forceMarch = document.querySelector("#force-march").checked;
    if (!forceMarch || unit.owner !== "roman" || unit.type !== "roman" || state.supply <= 0) return false;

    return areas[from].links.some((middle) => {
      const middleArea = areas[middle];
      if (!middleArea || middleArea.sea) return false;
      const blockers = areaUnits(middle).some((other) => isEnemy(other.owner, unit.owner) || other.owner === "neutral");
      return !blockers && middleArea.links.includes(target) && legalAreaForUnit(unit, target);
    });
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

    const unit = state.units[state.selectedUnit];
    if (unit.owner !== state.active) {
      log(`${unit.name} is not controlled by the active player.`);
      render();
      return;
    }

    if (!canMove(unit, target)) {
      log(`${unit.name} cannot move from ${areaName(unit.location)} to ${areaName(target)}.`);
      render();
      return;
    }

    const from = unit.location;
    const force = !areas[from].links.includes(target);
    unit.location = target;
    if (force) state.supply -= 1;

    areaUnits(target).forEach((other) => {
      if (other.owner === "neutral") {
        other.owner = state.active === "roman" ? "barbarian" : "roman";
        log(`${other.name} joins the ${playerName(other.owner)} player as ${unit.name} enters ${areaName(target)}.`);
      }
    });

    log(`${unit.name} moved to ${areaName(target)}${force ? " by forced march" : ""}.`);
    state.selectedUnit = null;
    render();
  }

  function playAction(action) {
    state.currentAction = action;
    const card = actionCard();
    if (!card) {
      log(state.mode === "hotseat" ? "Select and commit a card first." : "Select a Roman card first.");
      render();
      return;
    }

    if (action === "supply") {
      if (state.active === "roman") {
        state.supply = Math.min(19, state.supply + card.ap * 2);
        log(`Roman supply action with ${card.title}: +${card.ap * 2} supply.`);
      } else {
        state.supply = Math.max(0, state.supply - card.ap);
        log(`Barbarian raid with ${card.title}: -${card.ap} Roman supply.`);
      }
      discardSelectedCard();
    } else if (action === "activate") {
      if (!card.area) {
        log("Event cards cannot activate neutral tribes.");
      } else {
        activateArea(card.area, state.active);
        discardSelectedCard();
      }
    } else if (action === "political") {
      if (!state.selectedArea) {
        log("Select a target area before a political action.");
      } else {
        politicalAction(state.selectedArea, card);
        discardSelectedCard();
      }
    } else if (action === "event") {
      eventAction(card);
      discardSelectedCard();
    } else {
      log(`${playerName(state.active)} is using ${card.title} for movement. Select units on the map.`);
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

  function discardSelectedCard() {
    const hand = state.hands[state.active];
    const played = actionCard();
    const index = hand.findIndex((card) => card.id === played.id);
    if (index >= 0) state.discard.push(hand.splice(index, 1)[0]);
    if (state.mode === "hotseat") {
      state.committed[state.active] = null;
      state.revealed = Boolean(state.committed.roman || state.committed.barbarian);
    } else {
      drawBotCard();
    }
    state.selectedCard = null;
  }

  function commitCard() {
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
    state.committed[state.active] = state.selectedCard;
    state.selectedCard = null;
    log(`${playerName(state.active)} committed a card face down.`);
    render();
  }

  function revealCards() {
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
    state.revealed = true;
    log(`Cards revealed: Roman ${state.committed.roman.title}; Barbarian ${state.committed.barbarian.title}.`);
    render();
  }

  function drawBotCard() {
    if (state.mode === "ai") {
      log(gameData.ai.configured ? `AI opponent placeholder: ${gameData.ai.model || "configured model"} would choose the Barbarian response here.` : "AI opponent is not configured. Copy config/ai.yml.example to config/ai.yml and add a local API key.");
      return;
    }

    const card = state.botDeck.shift();
    if (!card) {
      log("Bot deck is empty.");
      return;
    }

    log(`Bot reveals ${card.title}.`);
    resolveBotCard(card);
    state.discard.push(card);
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

  function resolveBattles() {
    const battleAreas = contestedAreas();
    if (!battleAreas.length) {
      log("No battles to resolve.");
      render();
      return;
    }
    battleAreas.forEach(resolveBattle);
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

  function endTurn() {
    const harvest = d6();
    if (harvest === 1) state.supply = Math.max(0, state.supply - 2);
    if (harvest === 6) state.supply = Math.min(19, state.supply + 2);

    Object.values(state.units).forEach((unit) => {
      if (unit.location === "eliminated" && unit.type !== "roman") {
        unit.location = unit.home === "offboard" ? "offboard" : unit.home;
        unit.owner = "neutral";
        unit.step = 0;
      } else if (unit.type === "roman" && unit.location !== "eliminated" && unit.location !== "offboard") {
        unit.location = "transalpine_gaul";
      } else if ((unit.type === "barbarian" || unit.type === "leader") && unit.home !== "offboard" && unit.location !== "offboard") {
        unit.location = unit.home;
      } else if (unit.type === "german" && unit.location !== "eliminated") {
        unit.location = "germania";
      }
    });

    const controlledTribes = Object.keys(areas).filter((id) => {
      const area = areas[id];
      if (!area.region || area.region === "roman" || area.sea) return false;
      return areaUnits(id).some((unit) => unit.owner === "roman" && unit.type !== "roman");
    }).length;

    state.vp += controlledTribes;
    state.turn = Math.min(gameData.years.length - 1, state.turn + 1);
    log(`End turn complete. Harvest roll ${harvest}. Roman scores ${controlledTribes} tribal VP.`);
    dealCards();
  }

  function d6() {
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
    document.querySelectorAll(".player-button").forEach((button) => {
      button.classList.toggle("is-active", button.dataset.player === state.active);
    });
    els.selectedCard.textContent = state.selectedCard ? `${state.selectedCard.title}, AP ${state.selectedCard.ap}.` : "No card selected.";
    renderCommittedCards();
  }

  function renderStatus() {
    document.querySelector("#mode-label").textContent = modeName();
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
    Object.values(areas).forEach((area) => {
      if (area.sea) return;

      const rect = document.createElementNS("http://www.w3.org/2000/svg", "rect");
      rect.setAttribute("x", area.x - 4);
      rect.setAttribute("y", area.y - 3);
      rect.setAttribute("width", 8);
      rect.setAttribute("height", 6);
      rect.setAttribute("rx", 1);
      rect.classList.add("area-hotspot");
      rect.classList.toggle("is-selected", state.selectedArea === area.id);
      rect.addEventListener("click", () => moveSelectedTo(area.id));
      els.areaLayer.append(rect);
    });
  }

  function renderPieces() {
    els.pieceLayer.innerHTML = "";
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
        piece.classList.toggle("is-selected", state.selectedUnit === unit.id);
        piece.classList.toggle("is-hidden", unit.owner === "neutral");
        piece.style.left = `${area.x + offsetX}%`;
        piece.style.top = `${area.y + offsetY}%`;
        piece.title = `${unit.name} ${unit.owner} strength ${currentStrength(unit)}`;
        piece.innerHTML = `<img src="${unit.image}" alt="${unit.name}"><span class="strength-badge">${currentStrength(unit)}</span>`;
        piece.addEventListener("click", (event) => {
          event.stopPropagation();
          selectUnit(unit.id);
        });
        els.pieceLayer.append(piece);
      });
    });
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
      button.disabled = hidden || (state.mode === "hotseat" && (state.revealed || committed));
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

    if (state.mode === "hotseat") {
      help.textContent = "Hotseat: use the Roman/Barbarian buttons to pass control. Each side commits a hidden card, then reveal both.";
      commitButton.hidden = false;
      revealButton.hidden = false;
      botButton.hidden = true;
      barbarianButton.disabled = false;
    } else if (state.mode === "solitaire") {
      help.textContent = "Solitaire: you play Romans. After each Roman card resolves, the bot reveals the next deck card and follows the solo priority matrix.";
      commitButton.hidden = true;
      revealButton.hidden = true;
      botButton.hidden = false;
      barbarianButton.disabled = true;
    } else {
      help.textContent = gameData.ai.configured ? `AI mode: local config loaded for ${gameData.ai.model || "configured model"}. AI calls are not wired yet.` : "AI mode: copy config/ai.yml.example to config/ai.yml and add a local API key. AI calls are not wired yet.";
      commitButton.hidden = true;
      revealButton.hidden = true;
      botButton.hidden = false;
      barbarianButton.disabled = true;
    }
  }

  function renderLog() {
    els.log.innerHTML = state.log.map((entry) => `<li>${entry}</li>`).join("");
  }

  function saveGame() {
    localStorage.setItem("cgw2e-save", JSON.stringify(state));
    log("Game quick-saved in this browser.");
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
    log("Browser quick-save loaded.");
    render();
  }

  function saveGameFile() {
    const fallback = `cgw-${gameData.years[state.turn].toLowerCase().replaceAll(" ", "-")}.json`;
    const filename = prompt("Save game filename", fallback);
    if (!filename) {
      log("Save file canceled.");
      render();
      return;
    }

    const safeFilename = filename.endsWith(".json") ? filename : `${filename}.json`;
    const blob = new Blob([JSON.stringify(state, null, 2)], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.download = safeFilename;
    document.body.append(link);
    link.click();
    link.remove();
    URL.revokeObjectURL(url);
    log(`Prepared save file ${safeFilename}.`);
    render();
  }

  function chooseGameFile() {
    document.querySelector("#load-file-input").click();
  }

  function loadGameFile(event) {
    const file = event.target.files[0];
    if (!file) return;

    const reader = new FileReader();
    reader.addEventListener("load", () => {
      try {
        const loaded = JSON.parse(reader.result);
        validateSaveState(loaded);
        state = loaded;
        document.querySelector("#play-mode").value = state.mode || "hotseat";
        log(`Loaded save file ${file.name}.`);
        render();
      } catch (error) {
        log(`Could not load ${file.name}: ${error.message}`);
        render();
      } finally {
        event.target.value = "";
      }
    });
    reader.readAsText(file);
  }

  function validateSaveState(loaded) {
    if (!loaded || typeof loaded !== "object") throw new Error("not a game save");
    if (!loaded.units || !loaded.hands || !Number.isInteger(loaded.turn)) throw new Error("missing required game fields");
  }

  function setMode(mode) {
    state.mode = mode;
    state.active = "roman";
    state.selectedCard = null;
    state.committed = { roman: null, barbarian: null };
    state.revealed = false;
    log(`Mode changed to ${modeName()}. Dealing a fresh hand for this mode.`);
    dealCards();
  }

  function exportGame() {
    document.querySelector("#export-text").value = JSON.stringify(state, null, 2);
    document.querySelector("#export-dialog").showModal();
  }

  document.querySelector("#new-game").addEventListener("click", newGame);
  document.querySelector("#deal-cards").addEventListener("click", dealCards);
  document.querySelector("#commit-card").addEventListener("click", commitCard);
  document.querySelector("#reveal-cards").addEventListener("click", revealCards);
  document.querySelector("#bot-card").addEventListener("click", drawBotCard);
  document.querySelector("#play-mode").addEventListener("change", (event) => setMode(event.target.value));
  document.querySelector("#end-turn").addEventListener("click", endTurn);
  document.querySelector("#save-game").addEventListener("click", saveGame);
  document.querySelector("#load-game").addEventListener("click", loadGame);
  document.querySelector("#save-file").addEventListener("click", saveGameFile);
  document.querySelector("#load-file").addEventListener("click", chooseGameFile);
  document.querySelector("#load-file-input").addEventListener("change", loadGameFile);
  document.querySelector("#export-game").addEventListener("click", exportGame);
  document.querySelector("#resolve-battles").addEventListener("click", resolveBattles);
  document.querySelectorAll(".player-button").forEach((button) => button.addEventListener("click", () => setActive(button.dataset.player)));
  document.querySelectorAll("[data-action]").forEach((button) => button.addEventListener("click", () => playAction(button.dataset.action)));

  newGame();
});
