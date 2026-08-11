"use strict";

document.addEventListener("DOMContentLoaded", () => {
  const dataElement = document.querySelector("#game-data");
  if (!dataElement) return;

  const gameData = JSON.parse(dataElement.textContent);
  const areas = gameData.areas;
  const csrfToken = document.querySelector("meta[name='csrf-token']")?.content;

  let state;

  const els = {
    board: document.querySelector("#board"),
    boardStage: document.querySelector("#board-stage"),
    boardCanvas: document.querySelector("#board-canvas"),
    areaLayer: document.querySelector("#area-layer"),
    boardImage: document.querySelector("#board-canvas > img"),
    zoomMenu: document.querySelector("#zoom-menu"),
    mapZoom: document.querySelector("#map-zoom"),
    mapZoomButtons: [...document.querySelectorAll("[data-map-zoom]")],
    movementArrowLayer: document.querySelector("#movement-arrow-layer"),
    leaderHomeMarkerLayer: document.querySelector("#leader-home-marker-layer"),
    trackMarkerLayer: document.querySelector("#track-marker-layer"),
    pieceLayer: document.querySelector("#piece-layer"),
    neutralActivationLayer: document.querySelector("#neutral-activation-layer"),
    log: document.querySelector("#log"),
    selection: document.querySelector("#selection"),
    areaDetail: document.querySelector("#area-detail"),
    shell: document.querySelector(".shell"),
    sidePanel: document.querySelector("#side-panel"),
    toggleSidePanel: document.querySelector("#toggle-side-panel"),
    hotseatControls: document.querySelector("#hotseat-controls"),
    romanHand: document.querySelector("#roman-hand"),
    barbarianHand: document.querySelector("#barbarian-hand"),
    discardZone: document.querySelector("#discard-zone"),
    discardTitle: document.querySelector("#discard-title"),
    discardCount: document.querySelector("#discard-count"),
    discardPile: document.querySelector("#discard-pile"),
    handTray: document.querySelector("#hand-tray"),
    handTrayTitle: document.querySelector("#hand-tray-title"),
    toggleHand: document.querySelector("#toggle-hand"),
    cardZoom: document.querySelector("#card-zoom"),
    battleDialog: document.querySelector("#battle-dialog"),
    battleRollToast: document.querySelector("#battle-roll-toast"),
    battleRoundHeader: document.querySelector("#battle-round-header"),
    battleSummary: document.querySelector("#battle-summary"),
    battleZones: document.querySelector("#battle-zones"),
    battleDetails: document.querySelector("#battle-details"),
    battleActions: document.querySelector("#battle-actions"),
    resultDialog: document.querySelector("#result-dialog"),
    resultTitle: document.querySelector("#result-title"),
    resultMessage: document.querySelector("#result-message"),
    unitHistoryDialog: document.querySelector("#unit-history-dialog"),
    unitHistoryCounter: document.querySelector("#unit-history-counter"),
    unitHistoryKicker: document.querySelector("#unit-history-kicker"),
    unitHistoryTitle: document.querySelector("#unit-history-title"),
    unitHistoryText: document.querySelector("#unit-history-text"),
    unitHistoryHome: document.querySelector("#unit-history-home"),
    unitHistoryInitiative: document.querySelector("#unit-history-initiative"),
    unitHistoryBattleRating: document.querySelector("#unit-history-battle-rating"),
    mainForceDialog: document.querySelector("#main-force-dialog"),
    mainForceTitle: document.querySelector("#main-force-title"),
    mainForceMessage: document.querySelector("#main-force-message"),
    mainForceChoices: document.querySelector("#main-force-choices"),
    mainForceCancel: document.querySelector("#main-force-cancel"),
    winterQuartersPanel: document.querySelector("#winter-quarters-form"),
    winterQuartersForm: document.querySelector("#winter-quarters-form"),
    winterQuartersSummary: document.querySelector("#winter-quarters-summary"),
    winterQuartersSelection: document.querySelector("#winter-quarters-selection"),
    winterQuartersError: document.querySelector("#winter-quarters-error"),
    romanAdministrationDialog: document.querySelector("#roman-administration-dialog"),
    romanAdministrationForm: document.querySelector("#roman-administration-form"),
    romanAdministrationTitle: document.querySelector("#roman-administration-title"),
    romanAdministrationOptions: document.querySelector("#roman-administration-options"),
    romanAdministrationStatus: document.querySelector("#roman-administration-status"),
    romanAdministrationError: document.querySelector("#roman-administration-error"),
    romanAdministrationContinue: document.querySelector("#roman-administration-continue"),
    finishRegroup: document.querySelector("#finish-regroup"),
    gameMenu: document.querySelector("#game-menu"),
    modeMenu: document.querySelector("#mode-menu"),
    optionsMenu: document.querySelector("#options-menu"),
    playMode: document.querySelector("#play-mode"),
    playModeButtons: [...document.querySelectorAll("[data-play-mode]")],
    yearlyObjectives: document.querySelector("#yearly-objectives"),
    yearlyObjectivesToggle: document.querySelector("#yearly-objectives-toggle"),
    yearlyObjectivesPanel: document.querySelector("#yearly-objectives-panel"),
    historicalReinforcements: document.querySelector("#historical-reinforcements"),
    historicalReinforcementsToggle: document.querySelector("#historical-reinforcements-toggle"),
    postGameReport: document.querySelector("#post-game-report"),
    postGameReportToggle: document.querySelector("#post-game-report-toggle"),
    animatedDice: document.querySelector("#animated-dice"),
    movementSounds: document.querySelector("#movement-sounds"),
    movementArrows: document.querySelector("#movement-arrows"),
    optionalRulesStatus: document.querySelector("#optional-rules-status"),
    optionalRulesLabel: document.querySelector("#optional-rules-label"),
    objectiveTitle: document.querySelector("#objective-title"),
    objectiveYear: document.querySelector("#objective-year"),
    objectiveList: document.querySelector("#objective-list"),
    exportDialog: document.querySelector("#export-dialog"),
    exportText: document.querySelector("#export-text"),
    importDialog: document.querySelector("#import-dialog"),
    importForm: document.querySelector("#import-form"),
    importFile: document.querySelector("#import-file"),
    importText: document.querySelector("#import-text"),
    importError: document.querySelector("#import-error"),
    newGameDialog: document.querySelector("#new-game-dialog"),
    turnDialog: document.querySelector("#turn-dialog"),
    turnDialogForm: document.querySelector("#turn-dialog-form"),
    turnDialogTitle: document.querySelector("#turn-dialog-title"),
    turnDialogStatus: document.querySelector("#turn-dialog-status"),
    turnDialogVp: document.querySelector("#turn-dialog-vp"),
    turnDialogSupply: document.querySelector("#turn-dialog-supply"),
    acknowledgeTurn: document.querySelector("#acknowledge-turn"),
    botActionReviewDialog: document.querySelector("#bot-action-review-dialog"),
    botActionReviewCard: document.querySelector("#bot-action-review-card"),
    botActionReviewDragHandle: document.querySelector("#bot-action-review-drag-handle"),
    botActionReviewKicker: document.querySelector("#bot-action-review-kicker"),
    botActionReviewTitle: document.querySelector("#bot-action-review-title"),
    botActionReviewMessage: document.querySelector("#bot-action-review-message"),
    botActionReviewDetails: document.querySelector("#bot-action-review-details"),
    advanceBotActionReview: document.querySelector("#advance-bot-action-review"),
    battleTransitionDialog: document.querySelector("#battle-transition-dialog"),
    battleTransitionForm: document.querySelector("#battle-transition-form"),
    battleTransitionTitle: document.querySelector("#battle-transition-title"),
    battleTransitionMessage: document.querySelector("#battle-transition-message"),
    continueNextBattle: document.querySelector("#continue-next-battle"),
    revoltTargetPanel: document.querySelector("#revolt-target-panel"),
    revoltTargetTitle: document.querySelector("#revolt-target-title"),
    revoltTargetInstructions: document.querySelector("#revolt-target-instructions"),
    cancelRevoltTarget: document.querySelector("#cancel-revolt-target"),
    retreatTargetPanel: document.querySelector("#retreat-target-panel"),
    retreatTargetInstructions: document.querySelector("#retreat-target-instructions"),
    cancelRetreatTarget: document.querySelector("#cancel-retreat-target"),
    mainForceTargetPanel: document.querySelector("#main-force-target-panel"),
    mainForceTargetDragHandle: document.querySelector("#main-force-target-drag-handle"),
    mainForceTargetTitle: document.querySelector("#main-force-target-title"),
    mainForceTargetInstructions: document.querySelector("#main-force-target-instructions"),
    mainForceTargetOptions: document.querySelector("#main-force-target-options"),
    cancelMainForceTarget: document.querySelector("#cancel-main-force-target")
  };
  const mapZoomLevels = [0.5, 0.75, 1, 1.25, 1.5];
  const mapPanDirections = {
    KeyW: [0, -1],
    KeyA: [-1, 0],
    KeyS: [0, 1],
    KeyD: [1, 0]
  };
  const botRollToastDuration = 2150;
  const mapAspectRatio = 2080 / 1664;
  const hitMapSize = { width: 1664, height: 2080 };
  const minimumHitComponentSize = 2000;
  const territorySupplementalSeeds = {
    germania: [[94, 38]]
  };
  const territoryEdgeDirections = [[1, 0], [-1, 0], [0, 1], [0, -1], [1, 1], [1, -1], [-1, 1], [-1, -1]];
  let areaHitMap = null;
  const areaOverlayCache = new Map();
  let dragState = null;
  let suppressNextPieceClick = false;
  let piecesHidden = false;
  let handHidden = false;
  let sidePanelCollapsed = false;
  let zoomedCardId = null;
  let resultDialogQueue = [];
  let botActionReview = null;
  let botActionReviewDrag = null;
  let botRollReview = null;
  let diceRollAnimation = null;
  let gameAudioContext = null;
  let battleTransitionReview = null;
  let turnAnnouncementTimer = null;
  let turnAnnouncementBlocker = null;
  let revoltTargetSelection = null;
  let voluntaryRetreatSelection = null;
  let mainForceSelection = null;
  let mainForceTargetDrag = null;
  let splayedPieceStack = null;
  let boardResizeObserver = null;
  let mapPanFrame = null;
  let mapPanTimestamp = null;
  const mapPanKeys = new Set();
  let mapZoom = storedMapZoom();
  let animatedDice = storedAnimatedDice();
  let movementSounds = storedMovementSounds();
  let movementArrows = storedMovementArrows();

  function storedMapZoom() {
    try {
      const stored = Number(window.localStorage.getItem("cgw-map-zoom"));
      return mapZoomLevels.includes(stored) ? stored : 1;
    } catch (_error) {
      return 1;
    }
  }

  function storedAnimatedDice() {
    try {
      return window.localStorage.getItem("cgw-animated-dice") === "true";
    } catch (_error) {
      return false;
    }
  }

  function storedMovementSounds() {
    try {
      const stored = window.localStorage.getItem("cgw-movement-sounds");
      return stored === null ? true : stored === "true";
    } catch (_error) {
      return true;
    }
  }

  function storedMovementArrows() {
    try {
      const stored = window.localStorage.getItem("cgw-movement-arrows");
      return stored === null ? true : stored === "true";
    } catch (_error) {
      return true;
    }
  }

  function mapViewportCenter() {
    const width = els.boardStage.offsetWidth;
    const height = els.boardStage.offsetHeight;
    if (!width || !height) return { x: 0.5, y: 0 };
    return {
      x: (els.board.scrollLeft + (els.board.clientWidth / 2) - els.boardStage.offsetLeft) / width,
      y: (els.board.scrollTop + (els.board.clientHeight / 2) - els.boardStage.offsetTop) / height
    };
  }

  function layoutMapZoom({ preserveCenter = true } = {}) {
    if (!els.board || !els.boardStage || !els.boardCanvas) return;
    const center = preserveCenter ? mapViewportCenter() : null;
    const baseWidth = Math.min(980, Math.max(760, els.board.clientWidth));
    const baseHeight = baseWidth * mapAspectRatio;
    els.boardStage.style.width = `${baseWidth * mapZoom}px`;
    els.boardStage.style.height = `${baseHeight * mapZoom}px`;
    els.boardCanvas.style.width = `${baseWidth}px`;
    els.boardCanvas.style.height = `${baseHeight}px`;
    els.boardCanvas.style.transform = `scale(${mapZoom})`;
    positionMainForceTargetPanel();
    if (!center) {
      els.board.scrollLeft = Math.max(0, els.boardStage.offsetLeft + (els.boardStage.offsetWidth / 2) - (els.board.clientWidth / 2));
      els.board.scrollTop = 0;
      return;
    }

    window.requestAnimationFrame(() => {
      positionMainForceTargetPanel();
      els.board.scrollLeft = els.boardStage.offsetLeft + (center.x * els.boardStage.offsetWidth) - (els.board.clientWidth / 2);
      els.board.scrollTop = els.boardStage.offsetTop + (center.y * els.boardStage.offsetHeight) - (els.board.clientHeight / 2);
    });
  }

  function setMapZoom(value) {
    const requested = Number(value);
    if (!mapZoomLevels.includes(requested) || requested === mapZoom) return;
    mapZoom = requested;
    renderMapZoomControl();
    try {
      window.localStorage.setItem("cgw-map-zoom", String(mapZoom));
    } catch (_error) {
      // Zoom still works when browser storage is unavailable.
    }
    layoutMapZoom();
  }

  function renderMapZoomControl() {
    els.mapZoom.value = String(mapZoom);
    els.mapZoomButtons.forEach((button) => {
      button.setAttribute("aria-pressed", String(Number(button.dataset.mapZoom) === mapZoom));
    });
  }

  function mapPanDirection(code) {
    return mapPanDirections[code];
  }

  function mapPanBlocked(target = document.activeElement) {
    if (!els.board || document.querySelector("dialog[open]")) return true;
    if (!(target instanceof Element)) return false;
    return Boolean(target.closest("input, textarea, select, [contenteditable='true']"));
  }

  function startMapPan() {
    if (mapPanFrame) return;
    mapPanTimestamp = null;
    mapPanFrame = window.requestAnimationFrame(stepMapPan);
  }

  function stepMapPan(timestamp) {
    mapPanFrame = null;
    if (!mapPanKeys.size || mapPanBlocked()) {
      stopMapPan();
      return;
    }

    const elapsed = mapPanTimestamp === null
      ? 0
      : Math.min(0.05, (timestamp - mapPanTimestamp) / 1000);
    mapPanTimestamp = timestamp;

    let horizontal = 0;
    let vertical = 0;
    mapPanKeys.forEach((code) => {
      const [x, y] = mapPanDirection(code);
      horizontal += x;
      vertical += y;
    });

    const magnitude = Math.hypot(horizontal, vertical) || 1;
    const pixelsPerSecond = 680;
    els.board.scrollLeft += (horizontal / magnitude) * pixelsPerSecond * elapsed;
    els.board.scrollTop += (vertical / magnitude) * pixelsPerSecond * elapsed;
    mapPanFrame = window.requestAnimationFrame(stepMapPan);
  }

  function stopMapPan() {
    if (mapPanFrame) window.cancelAnimationFrame(mapPanFrame);
    mapPanFrame = null;
    mapPanTimestamp = null;
    mapPanKeys.clear();
  }

  async function newGame() {
    const mode = document.querySelector("#play-mode")?.value || "hotseat";
    const yearlyObjectives = Boolean(els.yearlyObjectives?.checked);
    const historicalReinforcements = Boolean(els.historicalReinforcements?.checked);
    const postGameReport = Boolean(els.postGameReport?.checked);
    try {
      const result = await postJson("/game_sessions", {
        mode,
        yearly_objectives: yearlyObjectives,
        historical_reinforcements: historicalReinforcements,
        post_game_report: postGameReport
      });
      state = result.state;
      state.gameSessionId = result.game_session_id;
      normalizeLoadedState();
      handHidden = false;
      zoomedCardId = null;
      render();
    } catch (error) {
      window.alert(`New game could not be created: ${error.message}`);
    }
  }

  function requestNewGame() {
    if (!state?.gameSessionId) {
      newGame();
      return;
    }
    els.newGameDialog.showModal();
  }

  async function startNewGameWithoutSaving() {
    els.newGameDialog.close();
    await newGame();
  }

  async function saveAndStartNewGame() {
    downloadExport(exportedGameJson());
    els.newGameDialog.close();
    await newGame();
  }

  function optionalRulesLocked() {
    return Boolean(
      state?.turn > 0 ||
      state?.discard?.length ||
      state?.currentAction ||
      state?.movement ||
      state?.battle ||
      state?.revealed ||
      state?.committed?.roman ||
      state?.committed?.barbarian ||
      state?.diceRolledThisTurn
    );
  }

  async function changeYearlyObjectives(enabled) {
    await changeOptionalRule("yearlyObjectives", enabled);
  }

  async function changeHistoricalReinforcements(enabled) {
    await changeOptionalRule("historicalReinforcements", enabled);
  }

  async function changePostGameReport(enabled) {
    await changeOptionalRule("postGameReport", enabled);
  }

  function changeAnimatedDice(enabled) {
    animatedDice = Boolean(enabled);
    try {
      window.localStorage.setItem("cgw-animated-dice", String(animatedDice));
    } catch (_error) {
      // The option still works for this session when browser storage is unavailable.
    }
    if (!animatedDice) resetDiceRollAnimation();
    render();
  }

  function changeMovementSounds(enabled) {
    movementSounds = Boolean(enabled);
    try {
      window.localStorage.setItem("cgw-movement-sounds", String(movementSounds));
    } catch (_error) {
      // The option still works for this session when browser storage is unavailable.
    }
    render();
  }

  function changeMovementArrows(enabled) {
    movementArrows = Boolean(enabled);
    try {
      window.localStorage.setItem("cgw-movement-arrows", String(movementArrows));
    } catch (_error) {
      // The option still works for this session when browser storage is unavailable.
    }
    renderMovementArrows();
  }

  async function changeOptionalRule(option, enabled) {
    if (!state) return;
    if (optionalRulesLocked()) {
      render();
      return;
    }

    const previous = Boolean(state.options?.[option]);
    state.options ||= {};
    state.options[option] = Boolean(enabled);
    render();

    try {
      await ensureGameSession();
      const result = await postJson(`/game_sessions/${state.gameSessionId}/update_options`, {
        yearly_objectives: Boolean(state.options.yearlyObjectives),
        historical_reinforcements: Boolean(state.options.historicalReinforcements),
        post_game_report: Boolean(state.options.postGameReport)
      });
      state.options = result.options;
    } catch (error) {
      state.options[option] = previous;
      log(error.message);
    }
    render();
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

  function romanShieldMarkup() {
    return `
      <svg class="roman-counter-shield" viewBox="0 0 100 100" aria-hidden="true">
        <path class="roman-shield-shell" d="M25 7Q16 10 16 22v56q0 12 9 15 25 7 50 0 9-3 9-15V22Q84 10 75 7 50 1 25 7Z"/>
        <path class="roman-shield-trim" d="M29 13q-7 2-7 11v52q0 8 7 11 21 6 42 0 7-3 7-11V24q0-9-7-11-21-6-42 0Z"/>
        <path class="roman-shield-bolt" d="m43 37-13 15h8l-7 14 18-19h-9l8-10Zm14 0 13 15h-8l7 14-18-19h9l-8-10Z"/>
        <circle class="roman-shield-boss-outer" cx="50" cy="50" r="14"/>
        <circle class="roman-shield-boss-inner" cx="50" cy="50" r="8"/>
      </svg>
    `;
  }

  function romanGrassCrownMarkup() {
    return `
      <svg class="roman-grass-crown" viewBox="0 0 100 42" aria-hidden="true">
        <path class="roman-grass-crown-band" d="M14 31Q50 8 86 31"/>
        <path class="roman-grass-crown-weave" d="M18 30 29 20l8 6 13-14 13 14 8-6 11 10"/>
        <path class="roman-grass-crown-blades" d="m25 25-7-13m17 8-3-15m14 10L46 2m19 18 3-15m7 20 7-13"/>
      </svg>
    `;
  }

  const navalTribes = new Set([
    "atrebates", "belgae", "bellovaci", "caletes", "cantiaci", "esuvii", "lemovicii",
    "luxovii", "morini", "osismi", "pictones", "santones", "venelli"
  ]);

  function barbarianCounterCulture(unit) {
    const imagePath = unit.image.toLowerCase();
    if (unit.type === "german" || imagePath.includes("/germania/")) return "german";
    if (imagePath.includes("/belgae/")) return "belgae";
    if (imagePath.includes("/aquitani/")) return "aquitani";
    return "celtae";
  }

  function barbarianCounterSeed(unit) {
    return [...unit.id].reduce((seed, character) => ((seed * 31) + character.charCodeAt(0)) >>> 0, 17);
  }

  function barbarianCounterName(unit) {
    return unit.name.replace(/^German\s*-\s*/i, "");
  }

  function barbarianDeviceMarkup(unit) {
    const seed = barbarianCounterSeed(unit);
    const shapes = [
      '<ellipse class="barbarian-device-field" cx="50" cy="53" rx="24" ry="31"/>',
      '<path class="barbarian-device-field" d="M50 17 76 29 70 69 50 88 30 69 24 29Z"/>',
      '<path class="barbarian-device-field" d="M29 19h42l9 27-12 37H32L20 46Z"/>',
      '<circle class="barbarian-device-field" cx="50" cy="53" r="30"/>',
      '<path class="barbarian-device-field" d="M27 20q23-8 46 0v56q-23 14-46 0Z"/>'
    ];
    const motifs = [
      '<path class="barbarian-device-motif-fill" d="M43 22h14v62H43Z"/>',
      '<path class="barbarian-device-motif-stroke" d="m29 65 21-25 21 25M31 77l19-23 19 23"/>',
      '<path class="barbarian-device-motif-fill" d="M44 27h12v20h19v13H56v20H44V60H25V47h19Z"/>',
      '<circle class="barbarian-device-motif-stroke" cx="50" cy="53" r="17"/><path class="barbarian-device-motif-stroke" d="M50 25v10m0 36v10M22 53h10m36 0h10M30 33l7 7m26 26 7 7m0-40-7 7M37 66l-7 7"/>',
      '<circle class="barbarian-device-motif-fill" cx="50" cy="38" r="8"/><circle class="barbarian-device-motif-fill" cx="38" cy="62" r="8"/><circle class="barbarian-device-motif-fill" cx="62" cy="62" r="8"/>',
      '<path class="barbarian-device-motif-stroke" d="M35 75q30-22 0-44m30 44Q35 53 65 31"/>',
      '<path class="barbarian-device-motif-fill" d="m50 27 18 26-18 26-18-26Z"/>',
      '<path class="barbarian-device-motif-stroke" d="M29 39q21 20 42 0M29 67q21-20 42 0"/>'
    ];
    const palettes = [
      ["#a43a32", "#edc75e", "#6e451b"],
      ["#315c78", "#e4c467", "#263c39"],
      ["#d1bb72", "#7e2f2d", "#614a25"],
      ["#446f42", "#e4cf86", "#283d28"],
      ["#704a78", "#e0bd5a", "#463143"],
      ["#d6773d", "#f0d790", "#754221"],
      ["#427878", "#e7c85d", "#294343"]
    ];
    const palette = palettes[Math.floor(seed / 7) % palettes.length];
    const shape = shapes[seed % shapes.length];
    const motif = motifs[Math.floor(seed / shapes.length) % motifs.length];
    return `
      <svg class="barbarian-counter-device" viewBox="0 0 100 100" aria-hidden="true"
           style="--device-field: ${palette[0]}; --device-motif: ${palette[1]}; --device-edge: ${palette[2]}">
        ${shape}
        ${motif}
        <circle class="barbarian-device-boss" cx="50" cy="53" r="7"/>
      </svg>
    `;
  }

  function barbarianSpecialMarkMarkup(unit) {
    let mark = null;
    let label = null;
    if (["helvetii", "vercingetorix"].includes(unit.id)) {
      mark = "★";
      label = "Special unit";
    } else if (unit.id === "nantuates") {
      mark = "+";
      label = "Mountain unit";
    } else if (unit.id === "treveri") {
      mark = "CAV";
      label = "Cavalry";
    } else if (navalTribes.has(unit.id)) {
      mark = "⚓";
      label = "Naval unit";
    }
    return mark ? `<span class="barbarian-counter-mark${mark.length > 1 ? " is-wide" : ""}" aria-label="${label}">${mark}</span>` : "";
  }

  function unitCounterMarkup(unit, { faceVisible = true, showStats = true, showStrength = true, halfHitOverride } = {}) {
    const strength = currentStrength(unit);
    const halfHit = halfHitOverride === undefined ? state.battle?.halfHits?.[unit.id] : halfHitOverride;
    const digitalRomanFace = faceVisible && unit.type === "roman";
    const digitalBarbarianFace = faceVisible && unit.type !== "roman";
    const caesarCounter = digitalRomanFace && unit.id === "legion_x";
    const barbarianName = digitalBarbarianFace ? barbarianCounterName(unit) : "";
    return `
      <span class="unit-counter-art${digitalRomanFace ? " has-digital-roman-face" : ""}${digitalBarbarianFace ? " has-digital-barbarian-face" : ""}">
        <img src="${unit.image}" alt="${faceVisible ? unit.name : "Hidden block"}">
        ${digitalRomanFace ? `
          <span class="roman-counter-face${caesarCounter ? " is-caesar" : ""}">
            <span class="roman-counter-name">${unit.name}</span>
            ${caesarCounter ? romanGrassCrownMarkup() : ""}
            ${romanShieldMarkup()}
          </span>
        ` : ""}
        ${digitalBarbarianFace ? `
          <span class="barbarian-counter-face culture-${barbarianCounterCulture(unit)}${unit.type === "leader" ? " is-leader" : ""}">
            <span class="barbarian-counter-name${barbarianName.length > 11 ? " is-very-long" : barbarianName.length > 9 ? " is-long" : ""}">${barbarianName}</span>
            ${barbarianDeviceMarkup(unit)}
            ${barbarianSpecialMarkMarkup(unit)}
          </span>
        ` : ""}
      </span>
      ${faceVisible ? `
        ${showStrength ? `
          <span class="unit-counter-strength" aria-label="Current strength ${strength}">
            <b>${strength}</b>
          </span>
        ` : ""}
        ${showStats ? `
          <span class="unit-counter-stats">
            <span class="unit-counter-stat unit-counter-initiative" aria-label="Initiative ${unit.initiative}"><b>${unit.initiative}</b></span>
            <span class="unit-counter-stat unit-counter-battle-rating" aria-label="Battle rating ${unit.fire}"><b>${unit.fire}</b></span>
          </span>
        ` : ""}
        ${halfHit ? `<span class="unit-counter-half-hit" aria-label="One half hit retained">½ <small>HIT</small></span>` : ""}
      ` : ""}
    `;
  }

  function areaUnits(areaId) {
    return Object.values(state.units).filter((unit) => unit.location === areaId);
  }

  function unitHistoryKind(unit) {
    if (unit.type === "roman") return "Roman Legion";
    if (unit.type === "leader") return "Gallic Leader";
    if (unit.id === "ariovistus") return "German King";
    if (unit.type === "german") return "Germanic People";
    return "Gallic Tribe";
  }

  function unitHistoryHome(unit) {
    if (areas[unit.home]) return areaName(unit.home);
    if (unit.type === "leader") return "Determined when the leader enters play";
    if (unit.home === "offboard") return "Enters through an event";
    return unit.home ? unit.home.replaceAll("_", " ") : "Not recorded";
  }

  function showUnitHistory(unitId) {
    const unit = state.units?.[unitId];
    if (!unit || !unitFaceVisibleToActivePlayer(unit) || !els.unitHistoryDialog) return;

    const reference = gameData.units?.[unitId] || {};
    els.unitHistoryKicker.textContent = unitHistoryKind(unit);
    els.unitHistoryTitle.textContent = unit.name;
    els.unitHistoryText.textContent = reference.history || `${unit.name} is represented in Caesar's Gallic War.`;
    els.unitHistoryCounter.innerHTML = unitCounterMarkup(unit);
    els.unitHistoryHome.textContent = unitHistoryHome(unit);
    els.unitHistoryInitiative.textContent = unit.initiative;
    els.unitHistoryBattleRating.textContent = unit.fire;

    if (els.unitHistoryDialog.open) els.unitHistoryDialog.close();
    els.unitHistoryDialog.showModal();
  }

  function unitFaceVisibleToActivePlayer(unit) {
    if (mainForceTargeting()) return unit.owner === state.active;
    if (voluntaryRetreatTargeting()) {
      return unit.owner === state.units[voluntaryRetreatSelection.unitId]?.owner;
    }
    if (battleMapMode()) {
      const mapOwner = retreatingOnMap() ? state.battle.retreating : state.battle.winner;
      return unit.owner === mapOwner;
    }
    return unit.owner === state.active;
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

  function isEnemy(left, right) {
    return left !== "neutral" && right !== "neutral" && left !== right;
  }

  function setActive(player) {
    if (state.mode !== "hotseat" && player === "barbarian") {
      log("In solitaire or AI mode, the Barbarian side is controlled by the opponent system.");
      render();
      return;
    }
    if (state.mode === "hotseat" && !state.revealed && state.committed?.[player]) {
      log(`${playerName(player)} has already committed a card.`);
      render();
      return;
    }
    const changingPlayer = player !== state.active;
    state.active = player;
    state.selectedUnit = null;
    state.selectedCard = null;
    if (changingPlayer && state.mode === "hotseat") {
      handHidden = true;
      zoomedCardId = null;
    }
    log(`${playerName(player)} player is active. Only that player's hand is visible.`);
    render();
  }

  function playerName(player) {
    return player === "roman" ? "Roman" : "Barbarian";
  }

  async function selectUnit(id) {
    if (mainForceTargeting()) {
      chooseMainForceUnit(id);
      return;
    }
    if (voluntaryRetreatTargeting()) {
      await chooseVoluntaryRetreatTarget(state.units[id]?.location);
      return;
    }
    if (revoltTargeting()) {
      chooseRevoltTargetUnit(id);
      return;
    }
    if (targetingPoliticalAction()) return;

    const unit = state.units[id];
    if (winterQuartersActive()) {
      toggleWinteringUnit(id);
      return;
    }
    if (battleMapMode()) {
      if (canBattleMapUnit(unit)) markUnitSelected(id);
      else await selectArea(unit.location);
      render();
      return;
    }

    if (!unitFaceVisibleToActivePlayer(unit)) {
      await selectArea(unit.location);
      return;
    }
    if (state.movement && unit.owner === state.active && !movementAreaActivated(movementOrigin(unit))) {
      await activateMovementArea(movementOrigin(unit));
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
    if (mainForceTargeting()) {
      chooseMainForceOrigin(id);
      return;
    }
    if (voluntaryRetreatTargeting()) {
      await chooseVoluntaryRetreatTarget(id);
      return;
    }
    if (revoltTargeting()) {
      chooseRevoltTargetArea(id);
      return;
    }
    if (targetingPoliticalAction()) {
      await resolvePoliticalTarget(id);
      return;
    }

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
    if (unit.location === target) return null;
    if (!legalAreaForUnit(unit, target)) return null;
    if (!canUnitMoveThisCard(unit)) return null;
    if (unit.location === "roman_off_map" && target !== "transalpine_gaul") return null;

    const directBorder = borderType(unit.location, target);
    if (directBorder) {
      if (borderHasCapacity(unit.location, target, directBorder)) {
        return {
          force: false,
          via: null,
          border: directBorder,
          steps: [{ from: unit.location, to: target, border: directBorder }]
        };
      }

      return null;
    }
    if (retreatMovement()) return null;

    const forceRoute = forceMarchRoute(unit, target);
    if (forceRoute) {
      return {
        force: true,
        via: forceRoute,
        steps: [
          { from: unit.location, to: forceRoute, border: borderType(unit.location, forceRoute) },
          { from: forceRoute, to: target, border: borderType(forceRoute, target) }
        ]
      };
    }

    return null;
  }

  function moveFailureReason(unit, target) {
    const targetArea = areas[target];
    if (!targetArea) return `${target} is not a known area.`;
    if (targetArea.sea) return `${unit.name} cannot move into ${areaName(target)} because it is a sea area.`;
    if (unit.location === "offboard" || unit.location === "eliminated") return `${unit.name} is not on the map.`;
    if (unit.location === target) return `${unit.name} is already in ${areaName(target)}.`;
    if (!legalAreaForUnit(unit, target)) return illegalAreaReason(unit, target);
    if (!state.movement) return "Play a card for movement before moving blocks.";
    if (unit.location === "roman_off_map" && target !== "transalpine_gaul") {
      return `${unit.name} may only move from the Roman Off-Map area to Transalpine Gaul.`;
    }

    const moved = state.movement.units?.[unit.id];
    if (unit.location === "roman_off_map" && !moved && state.movement.remaining <= 0) {
      return `No group activations remain to move ${unit.name} from the Roman Off-Map area.`;
    }
    if (!moved && !movementAreaActivated(unit.location)) return `Activate ${areaName(unit.location)} for movement before moving ${unit.name}.`;
    if (retreatMovement() && moved?.stopped) return `${unit.name} has already retreated from this battle.`;
    if (moved?.stopped) return `${unit.name} has already finished movement for this card.`;
    if (moved?.steps >= 2) return `${unit.name} has already moved two areas for this card.`;
    if (retreatMovement()) return `${unit.name} cannot retreat more than one area.`;
    if (moved && (unit.owner !== "roman" || unit.type !== "roman")) return `${unit.name} cannot move more than one area.`;
    if (moved && state.supply <= 0) return "Roman legions need 1 supply to move a second area.";

    const directBorder = borderType(unit.location, target);
    if (directBorder) {
      if (!borderHasCapacity(unit.location, target, directBorder)) return borderCapacityReason(unit.location, target, directBorder);
      return `${unit.name} cannot move from ${areaName(unit.location)} to ${areaName(target)}.`;
    }

    const forceReason = forceMarchFailureReason(unit, target);
    if (forceReason) return forceReason;
    return `${unit.name} cannot move from ${areaName(unit.location)} to ${areaName(target)}.`;
  }

  function canUnitMoveThisCard(unit) {
    if (!state.movement) return false;
    state.movement.units ||= {};
    const moved = state.movement.units[unit.id];
    if (unit.location === "roman_off_map" && !moved) {
      return movementAreaActivated(unit.location) && state.movement.remaining > 0;
    }
    if (!moved) return movementAreaActivated(unit.location);
    if (moved.stopped || moved.steps >= 2) return false;
    if (retreatMovement()) return false;
    return unit.owner === "roman" && unit.type === "roman" && state.supply > 0;
  }

  function forceMarchRoute(unit, target) {
    if (retreatMovement()) return null;
    if (unit.location === "roman_off_map") return null;
    if (unit.owner !== "roman" || unit.type !== "roman" || state.supply <= 0) return null;
    if (state.movement) state.movement.units ||= {};
    if (state.movement?.units[unit.id]?.steps) return null;

    const from = unit.location;
    return areas[from].links.find((middle) => {
      if (middle === target) return false;
      const middleArea = areas[middle];
      if (!middleArea || middleArea.sea || !middleArea.links.includes(target)) return false;
      const firstBorder = borderType(from, middle);
      const secondBorder = borderType(middle, target);
      if (!borderHasCapacity(from, middle, firstBorder) || !borderHasCapacity(middle, target, secondBorder)) return false;
      const blockers = areaUnits(middle).some((other) => isEnemy(other.owner, unit.owner) || other.owner === "neutral");
      return !blockers;
    }) || null;
  }

  function forceMarchFailureReason(unit, target) {
    if (unit.location === "roman_off_map") return `${unit.name} cannot force march from the Roman Off-Map area.`;
    if (unit.owner !== "roman" || unit.type !== "roman") return `${unit.name} cannot force march.`;
    if (state.supply <= 0) return "Roman legions need 1 supply to force march.";
    if (state.movement?.units?.[unit.id]?.steps) return `${unit.name} cannot force march after it has already moved.`;

    const from = unit.location;
    const routeExists = areas[from]?.links.some((middle) => {
      if (middle === target) return false;
      const middleArea = areas[middle];
      return middleArea && !middleArea.sea && middleArea.links.includes(target);
    });
    if (!routeExists) return `${unit.name} has no legal two-area route from ${areaName(from)} to ${areaName(target)}.`;

    const capacityBlock = areas[from].links.find((middle) => {
      if (middle === target) return false;
      const middleArea = areas[middle];
      if (!middleArea || middleArea.sea || !middleArea.links.includes(target)) return false;
      const firstBorder = borderType(from, middle);
      const secondBorder = borderType(middle, target);
      return !borderHasCapacity(from, middle, firstBorder) || !borderHasCapacity(middle, target, secondBorder);
    });
    if (capacityBlock) {
      const firstBorder = borderType(from, capacityBlock);
      const secondBorder = borderType(capacityBlock, target);
      if (!borderHasCapacity(from, capacityBlock, firstBorder)) return borderCapacityReason(from, capacityBlock, firstBorder);
      return borderCapacityReason(capacityBlock, target, secondBorder);
    }

    return `${unit.name} cannot force march because the intermediate area is occupied by enemy or neutral blocks.`;
  }

  function borderType(from, target) {
    return areas[from]?.borders?.[target] || (areas[from]?.links.includes(target) ? "regular" : null);
  }

  function borderCapacity(type) {
    if (type === "regular" || type === "black") return 4;
    if (type === "minor_river") return 2;
    return null;
  }

  function borderHasCapacity(from, target, type) {
    const capacity = borderCapacity(type);
    if (!capacity || !state.movement) return true;
    state.movement.crossings ||= {};
    return (state.movement.crossings[`${from}->${target}`] || 0) < capacity;
  }

  function borderCapacityReason(from, target, type) {
    const capacity = borderCapacity(type);
    return `No more than ${capacity} unit${capacity === 1 ? "" : "s"} may cross ${areaName(from)} to ${areaName(target)} this movement action.`;
  }

  function restrictedBorder(type) {
    return type === "minor_river";
  }

  function legalAreaForUnit(unit, target) {
    if (target === "roman_off_map") return unit.type === "roman";
    if (target === "germania") return unit.type === "roman" || unit.type === "german";
    return true;
  }

  function illegalAreaReason(unit, target) {
    if (target === "roman_off_map") return "Only Roman blocks may move to the Roman off-map area.";
    if (target === "germania") return "Only Roman and German blocks may move to Germania.";
    return `${unit.name} cannot enter ${areaName(target)}.`;
  }

  function moveSelectedTo(target) {
    if (mainForceTargeting()) {
      chooseMainForceOrigin(target);
      return;
    }
    if (voluntaryRetreatTargeting()) {
      chooseVoluntaryRetreatTarget(target);
      return;
    }
    if (!state.selectedUnit) {
      selectArea(target);
      return;
    }

    if (battleMapMode()) {
      battleMapUnitTo(state.selectedUnit, target);
      return;
    }

    moveUnitTo(state.selectedUnit, target);
  }

  async function battleMapUnitTo(unitId, target) {
    const unit = state.units[unitId];
    if (!canBattleMapUnit(unit)) {
      log(state.retreating ? "Select a defeated unit in the battle area to retreat." : "Select a victorious unit in the battle area to regroup.");
      render();
      return;
    }

    const origin = unit.location;
    primeGameAudio();
    await battleAction(state.retreating ? "forced_retreat" : "regroup", unitId, target);
    if (state.units[unitId]?.location !== origin) playWoodenPieceTap();
  }

  async function moveUnitTo(unitId, target) {
    if (state.battle) {
      log("Finish the active battle before moving units on the map.");
      render();
      return;
    }

    const unit = state.units[unitId];
    if (unit.owner !== state.active) {
      log(`${unit.name} is not controlled by the active player.`);
      render();
      return;
    }

    if (!state.movement) {
      log("Play a card for movement before moving blocks.");
      render();
      return;
    }

    if (!movementAreaActivated(movementOrigin(unit))) {
      log(`Activate ${areaName(movementOrigin(unit))} for movement before moving ${unit.name}.`);
      render();
      return;
    }

    const plan = movePlan(unit, target);
    if (!plan) {
      log(moveFailureReason(unit, target));
      render();
      return;
    }

    let moved = false;
    primeGameAudio();
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
      moved = true;
    } catch (error) {
      state.undoStack?.pop();
      log(error.message);
    }
    render();
    if (moved) playWoodenPieceTap();
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
      yearlyObjectiveProgress: structuredClone(state.yearlyObjectiveProgress || {}),
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
    moved.path ||= [];
    const steps = plan.steps || [{ from, to: target, border: plan.border }];
    steps.forEach((step) => moved.path.push(step));
    moved.entry = steps[steps.length - 1]?.from || from;

    if (plan.force) {
      moved.force = true;
      moved.steps = 2;
      moved.stopped = true;
      state.supply -= 1;
      return;
    }

    moved.steps += 1;
    if (moved.steps >= 2 && !moved.naval) moved.force = true;
    if (retreatMovement()) {
      moved.stopped = true;
      return;
    }

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

    if (action !== "political") state.targetingAction = null;
    if (action === "supply") {
      const message = await performCardAction("supply_action");
      if (message) {
        showResultDialog(`${playerName(state.active)} Action - Supply Action`, message);
        await discardSelectedCard();
      }
    } else if (action === "activate") {
      const message = await performCardAction("activate_neutral");
      if (message) {
        showResultDialog(`${playerName(state.active)} Action - Neutral Tribe Activation`, message);
        await discardSelectedCard();
      }
    } else if (action === "political") {
      startPoliticalTargeting();
    } else if (action === "event") {
      const eventTarget = await chooseEventTarget(card);
      if (eventTarget === false) return;
      if (await performCardAction("event_action", eventTarget) && !state.battle) await discardSelectedCard();
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
    if (owner === "roman" && romanSpecialTargetBlockReason(areaId, "neutral activation")) {
      log(romanSpecialTargetBlockReason(areaId, "neutral activation"));
      return;
    }

    areaUnits(areaId).filter((unit) => unit.owner === "neutral").forEach((unit) => {
      unit.owner = owner;
      unit.step = 0;
    });
    log(`${playerName(owner)} activates ${areaName(areaId)}.`);
  }

  function takeNeutralActivation(areaId, owner) {
    if (owner === "roman" && romanSpecialTargetBlockReason(areaId, "neutral activation")) {
      log(romanSpecialTargetBlockReason(areaId, "neutral activation"));
      return;
    }

    const activatedUnits = areaUnits(areaId).filter((unit) => unit.owner === "neutral");
    activatedUnits.forEach((unit) => {
      unit.owner = owner;
      unit.step = 0;
    });
    const names = activatedUnits.map((unit) => unit.name).join(" and ") || areaName(areaId);
    const plural = activatedUnits.length > 1;
    log(`${names} ${plural ? `become ${playerName(owner)} allies` : `becomes a ${playerName(owner)} ally`}.`);
  }

  async function performCardAction(endpoint, extra = {}) {
    try {
      await ensureGameSession();
      const result = await postJson(`/game_sessions/${state.gameSessionId}/${endpoint}`, { state, ...extra });
      state = result.state;
      state.gameSessionId = result.game_session_id;
      normalizeLoadedState();
      return state.log?.[0] || true;
    } catch (error) {
      log(error.message);
      return false;
    }
  }

  function startPoliticalTargeting() {
    state.currentAction = "political";
    state.targetingAction = "political";
    state.selectedUnit = null;
    state.selectedArea = null;
    els.selection.textContent = `${playerName(state.active)}-controlled tribes are highlighted. Select a political action target.`;
    els.areaDetail.textContent = "Blocks are hidden while choosing.";
    log("Political action: select a target area.");
  }

  function targetingPoliticalAction() {
    return state.targetingAction === "political";
  }

  function revoltTargeting() {
    return Boolean(revoltTargetSelection);
  }

  function revoltTargetEligible(unit) {
    return Boolean(unit && revoltTargetSelection?.unitIds.has(unit.id));
  }

  function revoltTargetAreaIds() {
    if (!revoltTargetSelection) return [];
    return [...revoltTargetSelection.unitIds]
      .map((unitId) => state.units[unitId]?.location)
      .filter((areaId, index, ids) => areaId && ids.indexOf(areaId) === index);
  }

  function chooseRevoltTargetUnit(unitId) {
    const unit = state.units[unitId];
    if (!revoltTargetEligible(unit)) {
      els.selection.textContent = "Choose one of the highlighted Barbarian-controlled tribes.";
      return;
    }

    state.selectedUnit = unitId;
    state.selectedArea = unit.location;
    revoltTargetSelection.settle(unitId);
  }

  function chooseRevoltTargetArea(areaId) {
    if (!revoltTargetSelection) return;
    const candidates = [...revoltTargetSelection.unitIds]
      .map((unitId) => state.units[unitId])
      .filter((unit) => unit?.location === areaId);
    if (!candidates.length) {
      els.selection.textContent = "Choose a highlighted area or tribe.";
      return;
    }
    if (candidates.length === 1) {
      chooseRevoltTargetUnit(candidates[0].id);
      return;
    }

    revoltTargetSelection.focusedArea = areaId;
    state.selectedArea = areaId;
    els.selection.textContent = `Choose ${candidates.map((unit) => unit.name).join(" or ")} in ${areaName(areaId)}.`;
    render();
  }

  function activePlayerControlsPoliticalArea(areaId) {
    return Object.values(state.units).some((unit) =>
      unit.type === "barbarian" &&
      unit.home === areaId &&
      unit.owner === state.active &&
      !["eliminated", "offboard"].includes(unit.location) &&
      currentStrength(unit) > 0
    );
  }

  async function resolvePoliticalTarget(areaId) {
    const blocked = state.active === "roman" && romanSpecialTargetBlockReason(areaId, "political action");
    if (blocked) {
      log(blocked);
      render();
      return;
    }

    try {
      await ensureGameSession();
      const result = await postJson(`/game_sessions/${state.gameSessionId}/political_action`, { state, area_id: areaId });
      const resultMessage = result.state.log?.[0] || `Political action resolved in ${areaName(areaId)}.`;
      state = result.state;
      state.gameSessionId = result.game_session_id;
      state.targetingAction = null;
      normalizeLoadedState();
      showResultDialog(resultMessage.includes("succeeds") ? "Political Success" : "Political Failure", resultMessage);
      if (!state.battle) await discardSelectedCard();
    } catch (error) {
      log(error.message);
    }
    render();
  }

  function showResultDialog(title, message, options = {}) {
    if (!els.resultDialog) {
      window.alert(message);
      return;
    }
    const result = { title, message, reportGroups: options.reportGroups || null };
    if (els.resultDialog.open) {
      resultDialogQueue.push(result);
      return;
    }
    displayResultDialog(result);
  }

  function displayResultDialog(result) {
    els.resultTitle.textContent = result.title;
    els.resultDialog.classList.toggle("is-action-report", Boolean(result.reportGroups));
    els.resultMessage.replaceChildren();
    if (result.reportGroups) {
      renderActionReport(result.reportGroups);
    } else {
      els.resultMessage.textContent = result.message;
    }
    els.resultDialog.showModal();
  }

  function renderActionReport(groups) {
    const report = document.createElement("div");
    report.className = "action-report";

    groups.forEach((group) => {
      if (group.kind === "battle") {
        const section = document.createElement("section");
        section.className = "action-report-battle";

        const heading = document.createElement("h3");
        heading.textContent = `Battle · ${group.area}`;
        section.appendChild(heading);

        const events = document.createElement("ul");
        group.entries.forEach((entry) => {
          const item = document.createElement("li");
          item.textContent = entry;
          item.classList.toggle("is-outcome", botReportEntryKind(entry).key === "outcome");
          events.appendChild(item);
        });
        section.appendChild(events);
        report.appendChild(section);
        return;
      }

      const row = document.createElement("div");
      const entryKind = botReportEntryKind(group.message);
      row.className = `action-report-row is-${entryKind.key}`;

      const label = document.createElement("span");
      label.className = "action-report-label";
      label.textContent = entryKind.label;

      const message = document.createElement("p");
      message.textContent = group.message;

      row.append(label, message);
      report.appendChild(row);
    });

    els.resultMessage.appendChild(report);
  }

  function showNextResultDialog() {
    if (!resultDialogQueue.length) {
      showBattleTransitionReview();
      showTurnAnnouncement();
      showBotActionReview();
      return;
    }
    displayResultDialog(resultDialogQueue.shift());
  }

  function showBattleTransitionReview() {
    if (!battleTransitionReview || !els.battleTransitionDialog) return;
    if (els.battleTransitionDialog.open || document.querySelector("dialog[open]")) return;

    els.battleTransitionTitle.textContent = `Next Battle: ${areaName(battleTransitionReview.to)}`;
    els.battleTransitionMessage.textContent = `The battle in ${areaName(battleTransitionReview.from)} is complete. Another unresolved battle is ready.`;
    els.continueNextBattle.textContent = `Continue to ${areaName(battleTransitionReview.to)}`;
    els.battleTransitionDialog.showModal();
  }

  function continueToNextBattle(event) {
    event.preventDefault();
    if (!battleTransitionReview) return;

    const nextArea = battleTransitionReview.to;
    battleTransitionReview = null;
    if (els.battleTransitionDialog?.open) els.battleTransitionDialog.close();
    focusBoardArea(nextArea);
    render();
  }

  function turnAnnouncementText() {
    const year = String(gameData.years[state.turn] || "").replace(/\s+/g, "");
    return `Turn ${state.turn + 1}${year ? ` (${year})` : ""}`;
  }

  function setHandTrayTurnLocked(locked) {
    if (!els.handTray) return;
    els.handTray.classList.toggle("is-turn-locked", locked);
    els.handTray.toggleAttribute("inert", locked);
    els.handTray.setAttribute("aria-disabled", String(locked));
  }

  function showTurnAnnouncement({ immediate = false } = {}) {
    if (!state?.turnAnnouncementPending || state.gameOver || !state.gameSessionId || !els.turnDialog) {
      if (turnAnnouncementTimer) window.clearTimeout(turnAnnouncementTimer);
      turnAnnouncementTimer = null;
      turnAnnouncementBlocker = null;
      setHandTrayTurnLocked(false);
      return;
    }
    if (els.turnDialog.open) return;

    const blocker = document.querySelector("dialog[open]");
    if (blocker) {
      if (turnAnnouncementBlocker !== blocker) {
        turnAnnouncementBlocker = blocker;
        blocker.addEventListener("close", () => {
          if (turnAnnouncementBlocker === blocker) turnAnnouncementBlocker = null;
          showTurnAnnouncement();
        }, { once: true });
      }
      return;
    }

    if (!immediate) {
      if (turnAnnouncementTimer) return;
      turnAnnouncementTimer = window.setTimeout(() => {
        turnAnnouncementTimer = null;
        showTurnAnnouncement({ immediate: true });
      }, 250);
      return;
    }

    turnAnnouncementBlocker = null;
    els.turnDialogTitle.textContent = turnAnnouncementText();
    const showStatus = state.mode === "solitaire";
    els.turnDialogStatus.hidden = !showStatus;
    if (showStatus) {
      els.turnDialogVp.textContent = state.vp;
      els.turnDialogSupply.textContent = state.supply;
    }
    setHandTrayTurnLocked(true);
    els.turnDialog.show();
  }

  async function acknowledgeTurnAnnouncement(event) {
    event.preventDefault();
    if (turnAnnouncementTimer) window.clearTimeout(turnAnnouncementTimer);
    turnAnnouncementTimer = null;
    if (!state?.turnAnnouncementPending) {
      els.turnDialog.close();
      return;
    }

    els.acknowledgeTurn.disabled = true;
    try {
      const result = await postJson(`/game_sessions/${state.gameSessionId}/acknowledge_turn`, {});
      state = result.state;
      state.gameSessionId = result.game_session_id;
      normalizeLoadedState();
      els.turnDialog.close();
      render();
    } catch (error) {
      window.alert(`The turn announcement could not be acknowledged: ${error.message}`);
    } finally {
      els.acknowledgeTurn.disabled = false;
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

  function retreatMovement() {
    return Boolean(state.movement?.retreat);
  }

  function movementOrigin(unit) {
    return state.movement?.units?.[unit.id]?.origin || unit.location;
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
    const matchingCard = card.area === areaId;
    const opposingUnit = areaUnits(areaId).some((unit) => unit.owner !== state.active && unit.owner !== "neutral");
    let modified = roll;
    if (matchingCard) modified -= 1;
    if (opposingUnit) modified += 1;

    const modifiers = [];
    if (matchingCard) modifiers.push("matching card -1");
    if (opposingUnit) modifiers.push("opposing unit +1");
    const modifierSummary = modifiers.length ? `${modifiers.join(", ")}; ` : "";

    if (modified <= card.ap) {
      areaUnits(areaId).forEach((unit) => {
        if (unit.type !== "roman" && unit.type !== "german") {
          unit.owner = state.active;
          unit.location = unit.home;
        }
      });
      log(`Political action succeeds in ${area.name}: rolled ${roll}; ${modifierSummary}modified ${modified}; AP ${card.ap}.`);
    } else {
      log(`Political action fails in ${area.name}: rolled ${roll}; ${modifierSummary}modified ${modified}; AP ${card.ap}.`);
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

    const effectiveTitle = card.title === "Massive Revolt" && state.active === "barbarian" && state.turn === 0 ? "Minor Revolt" : card.title;
    const count = effectiveTitle === "Massive Revolt" ? 3 : effectiveTitle === "Major Revolt" ? 2 : 1;
    if (effectiveTitle !== card.title) log(`Turn 1: ${card.title} is treated as a ${effectiveTitle}.`);
    activateArea(state.selectedArea, state.active === "roman" ? "roman" : "barbarian");
    if (effectiveTitle === "Massive Revolt" && state.active === "barbarian") {
      const v = state.units.vercingetorix;
      v.location = state.selectedArea;
      v.owner = "barbarian";
    }
    log(`${effectiveTitle} resolved for ${areaName(state.selectedArea)}. Apply up to ${count} selected areas manually if needed.`);
  }

  async function chooseEventTarget(card) {
    if (!card.title?.includes("Revolt") || state.active !== "roman") return { area_id: state.selectedArea };

    const targets = romanRevoltTargets();
    if (!targets.length) {
      log(`${card.title} has no active Barbarian-controlled tribe targets.`);
      return false;
    }

    const unitId = await chooseRevoltTargetOnMap(card, targets);
    if (!unitId) return false;

    return { unit_id: unitId };
  }

  function chooseRevoltTargetOnMap(card, targets) {
    return new Promise((resolve) => {
      let settled = false;
      const previousPiecesHidden = piecesHidden;
      const settle = (value) => {
        if (settled) return;
        settled = true;
        revoltTargetSelection = null;
        piecesHidden = previousPiecesHidden;
        render();
        resolve(value);
      };

      revoltTargetSelection = {
        title: card.title,
        unitIds: new Set(targets.map((unit) => unit.id)),
        focusedArea: null,
        settle
      };
      piecesHidden = false;
      state.selectedUnit = null;
      state.selectedArea = null;
      els.selection.textContent = `${card.title}: choose a highlighted Barbarian-controlled tribe. Its current area and home are shown on the counter tooltip.`;
      els.areaDetail.textContent = "Click a highlighted counter. Hover over a stack to separate its tribes.";
      render();
      document.querySelector("#board")?.scrollIntoView({ block: "center", inline: "center" });
    });
  }

  function romanRevoltTargets() {
    return Object.values(state.units)
      .filter((unit) =>
        unit.owner === "barbarian" &&
        unit.type === "barbarian" &&
        unit.home &&
        unit.location &&
        !["eliminated", "offboard"].includes(unit.location) &&
        currentStrength(unit) > 0 &&
        areas[unit.home]?.region !== "germania"
      )
      .sort((a, b) => a.name.localeCompare(b.name));
  }

  function currentActionCard() {
    const selected = actionCard();
    if (selected) return selected;

    const cardId = state.movement?.cardId;
    if (!cardId) return null;
    return state.hands?.[state.active]?.find((card) => card.id === cardId) || null;
  }

  async function discardSelectedCard(played = currentActionCard()) {
    if (!played) return;

    // A battle response can replace the local state just before the action is
    // discarded. Keep the card that began the action attached long enough to
    // complete the solitaire handoff to the bot.
    if (!actionCard() && state.mode !== "hotseat" && state.active === "roman") {
      state.selectedCard = state.hands?.roman?.find((card) => card.id === played.id) || null;
    }
    if (!actionCard()) return;

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
      handHidden = true;
      zoomedCardId = null;
      const otherPlayer = state.active === "roman" ? "barbarian" : "roman";
      if (!state.committed[otherPlayer]) state.active = otherPlayer;
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
    const previousLog = [...(state.log || [])];
    try {
      await ensureGameSession();
      const result = await postJson(`/game_sessions/${state.gameSessionId}/draw_bot_card`, { state });
      state = result.state;
      state.gameSessionId = result.game_session_id;
      normalizeLoadedState();
      beginBotActionReview(previousLog, state.log || []);
    } catch (error) {
      log(error.message);
    }
    render();
  }

  function beginBotActionReview(previousLog, nextLog) {
    resetBotActionReviewDialogPosition();
    const previousHead = previousLog[0];
    const firstOldIndex = previousHead ? nextLog.indexOf(previousHead) : -1;
    const entries = firstOldIndex >= 0 ? nextLog.slice(0, firstOldIndex) : nextLog.slice(0, 5);
    const revealedCard = entries.find((entry) => entry.startsWith("Bot reveals "))?.replace(/^Bot reveals /, "").replace(/\.$/, "");
    const card = [...(state.discard || []), ...(state.removedCards || [])]
      .reverse()
      .find((candidate) => candidate.title === revealedCard);
    const actionEntries = entries
      .filter((entry) => !entry.startsWith("Bot reveals "))
      .reverse()
      .map((entry) => botActionSummary(entry, revealedCard).message);
    const movementMessages = actionEntries.filter((entry) => botReportEntryKind(entry).key === "movement");
    const battleMessages = actionEntries.filter((entry) =>
      /^Battle board opened for /.test(entry) || botReportEntryKind(entry).battleDetail
    );
    const actionMessages = actionEntries.filter((entry) =>
      !movementMessages.includes(entry) && !battleMessages.includes(entry)
    );
    const actionLabel = botActionReviewLabel(card, actionEntries);
    const movementRoutes = movementMessages.map(botMovementRoute).filter(Boolean);
    const revoltMovementTitle = botRevoltMovementTitle(card);
    const stages = [
      {
        kind: "action",
        kicker: "Barbarian Action",
        title: actionLabel,
        message: `${revealedCard || "The card"} is resolved as ${indefiniteArticle(actionLabel)} ${actionLabel.toLowerCase()}.`,
        details: actionMessages
      }
    ];
    if (movementMessages.length) {
      stages.push({
        kind: "movement",
        kicker: revoltMovementTitle ? "" : "Barbarian Movement",
        title: revoltMovementTitle || "Units Move",
        message: "The Barbarian units have moved on the map.",
        details: movementMessages
      });
    }

    botActionReview = {
      card,
      stages,
      stageIndex: 0,
      movementRoutes,
      battlePending: Boolean(state.battle),
      movementFocused: false,
      movementPositioned: false
    };
  }

  function botRevoltMovementTitle(card) {
    if (card?.title === "Massive Revolt") return state.turn === 0 ? "Major Revolt" : "Massive Revolt";
    if (card?.title === "Major Revolt") return "Major Revolt";
    return null;
  }

  function botActionReviewLabel(card, messages) {
    const recordedAction = state.lastBotAction?.cardId === card?.id
      ? state.lastBotAction.kind
      : null;
    const recordedLabels = {
      event: "Event",
      movement: "Movement",
      political_action: "Political Action",
      neutral_tribe_activation: "Neutral Tribe Activation"
    };
    if (recordedLabels[recordedAction]) return recordedLabels[recordedAction];

    if (card?.title === "Baggage Train" && messages.some((message) => botReportEntryKind(message).key === "movement")) {
      return "Movement";
    }
    if (card?.type === "event") return "Event";
    if (messages.some((message) => /political action/i.test(message))) return "Political Action";
    if (messages.some((message) => botReportEntryKind(message).key === "movement")) return "Movement";
    if (messages.some((message) => ["activation", "control"].includes(botReportEntryKind(message).key))) {
      return "Neutral Tribe Activation";
    }
    return "Action";
  }

  function indefiniteArticle(label) {
    return /^[aeiou]/i.test(label) ? "an" : "a";
  }

  function areaIdForName(name) {
    return Object.keys(areas).find((areaId) => areaName(areaId) === name.trim());
  }

  function botMovementRoute(message) {
    const match = message.match(/^Barbarian moves (.+) from (.+) to (.+)\.$/);
    if (!match) return null;

    const from = areaIdForName(match[2]);
    const to = areaIdForName(match[3]);
    if (!from || !to) return null;
    const battleEntries = Object.entries(state.battle?.entries || {});
    const count = battleEntries.filter(([unitId, origin]) =>
      origin === from && state.units[unitId]?.location === to && state.units[unitId]?.owner === "barbarian"
    ).length || match[1].split(", ").length;
    return { owner: "barbarian", from, to, count };
  }

  function currentBotActionReviewStage() {
    return botActionReview?.stages?.[botActionReview.stageIndex] || null;
  }

  function showBotActionReview() {
    const stage = currentBotActionReviewStage();
    if (!stage || !els.botActionReviewDialog || els.botActionReviewDialog.open) return;
    const movementStage = stage.kind === "movement";
    if (movementStage) {
      if (!botActionReview.movementFocused) {
        botActionReview.movementFocused = true;
        focusBoardArea(botActionReview.movementRoutes.at(-1)?.to);
      }
    }
    if (document.querySelector("dialog[open]")) return;

    const image = botActionReview.card ? cardImage(botActionReview.card) : null;
    const showCard = Boolean(image && !movementStage);
    els.botActionReviewDialog.classList.toggle("is-movement-review", movementStage);
    els.botActionReviewCard.hidden = !showCard;
    if (showCard) {
      els.botActionReviewCard.src = image;
      els.botActionReviewCard.alt = `${botActionReview.card.title} card`;
    }
    els.botActionReviewKicker.textContent = stage.kicker;
    els.botActionReviewKicker.hidden = !stage.kicker;
    els.botActionReviewTitle.textContent = stage.title;
    els.botActionReviewMessage.textContent = stage.message;
    els.botActionReviewDetails.replaceChildren(...stage.details.map((detail) => {
      const item = document.createElement("li");
      item.textContent = detail;
      return item;
    }));

    const finalStage = botActionReview.stageIndex >= botActionReview.stages.length - 1;
    const nextStage = botActionReview.stages[botActionReview.stageIndex + 1];
    els.advanceBotActionReview.textContent = movementStage
      ? (botActionReview.battlePending ? "Continue to Battle" : "Finish Review")
      : nextStage?.kind === "movement"
        ? "Show Movement"
        : finalStage && botActionReview.battlePending
          ? "Continue to Battle"
          : finalStage
            ? "OK"
            : "Continue";
    els.botActionReviewDialog.showModal();
    if (movementStage && !botActionReview.movementPositioned) {
      botActionReview.movementPositioned = true;
      window.requestAnimationFrame(positionBotActionReviewDialog);
    }
  }

  function resetBotActionReviewDialogPosition() {
    const dialog = els.botActionReviewDialog;
    if (!dialog) return;
    dialog.style.removeProperty("inset");
    dialog.style.removeProperty("left");
    dialog.style.removeProperty("top");
    dialog.style.removeProperty("right");
    dialog.style.removeProperty("bottom");
    dialog.style.removeProperty("margin");
  }

  function botMovementViewportPoint() {
    const routeAreas = (botActionReview?.movementRoutes || [])
      .flatMap((route) => [areas[route.from], areas[route.to]])
      .filter(Boolean);
    if (!routeAreas.length || !els.boardStage) {
      return { x: window.innerWidth / 2, y: window.innerHeight / 2 };
    }

    const stageRect = els.boardStage.getBoundingClientRect();
    return {
      x: routeAreas.reduce((sum, area) => sum + stageRect.left + ((area.x / 100) * stageRect.width), 0) / routeAreas.length,
      y: routeAreas.reduce((sum, area) => sum + stageRect.top + ((area.y / 100) * stageRect.height), 0) / routeAreas.length
    };
  }

  function positionBotActionReviewDialog() {
    const dialog = els.botActionReviewDialog;
    if (!dialog?.open || !dialog.classList.contains("is-movement-review")) return;

    const dialogRect = dialog.getBoundingClientRect();
    const movementPoint = botMovementViewportPoint();
    const edgeGap = 16;
    const left = movementPoint.x >= window.innerWidth / 2
      ? edgeGap
      : window.innerWidth - dialogRect.width - edgeGap;
    const top = Math.min(
      Math.max(edgeGap, movementPoint.y - (dialogRect.height / 2)),
      Math.max(edgeGap, window.innerHeight - dialogRect.height - edgeGap)
    );
    setBotActionReviewDialogPosition(left, top);
  }

  function setBotActionReviewDialogPosition(left, top) {
    const dialog = els.botActionReviewDialog;
    if (!dialog) return;
    const edgeGap = 8;
    const maxLeft = Math.max(edgeGap, window.innerWidth - dialog.offsetWidth - edgeGap);
    const maxTop = Math.max(edgeGap, window.innerHeight - dialog.offsetHeight - edgeGap);
    dialog.style.inset = "auto";
    dialog.style.margin = "0";
    dialog.style.left = `${Math.min(Math.max(edgeGap, left), maxLeft)}px`;
    dialog.style.top = `${Math.min(Math.max(edgeGap, top), maxTop)}px`;
  }

  function beginBotActionReviewDrag(event) {
    const dialog = els.botActionReviewDialog;
    if (event.button !== 0 || !dialog?.classList.contains("is-movement-review")) return;
    const rect = dialog.getBoundingClientRect();
    botActionReviewDrag = {
      pointerId: event.pointerId,
      offsetX: event.clientX - rect.left,
      offsetY: event.clientY - rect.top
    };
    event.currentTarget.setPointerCapture(event.pointerId);
    dialog.classList.add("is-dragging");
    event.preventDefault();
  }

  function moveBotActionReviewDialog(event) {
    if (!botActionReviewDrag || event.pointerId !== botActionReviewDrag.pointerId) return;
    setBotActionReviewDialogPosition(
      event.clientX - botActionReviewDrag.offsetX,
      event.clientY - botActionReviewDrag.offsetY
    );
  }

  function endBotActionReviewDrag(event) {
    if (!botActionReviewDrag || event.pointerId !== botActionReviewDrag.pointerId) return;
    botActionReviewDrag = null;
    els.botActionReviewDialog?.classList.remove("is-dragging");
  }

  function advanceBotActionReview() {
    if (!botActionReview) return;
    if (els.botActionReviewDialog.open) els.botActionReviewDialog.close();

    if (botActionReview.stageIndex < botActionReview.stages.length - 1) {
      botActionReview.stageIndex += 1;
      render();
      return;
    }

    botActionReview = null;
    resetBotActionReviewDialogPosition();
    render();
  }

  function focusBoardArea(areaId) {
    const area = areas[areaId];
    if (!area || !els.board || !els.boardStage) return;

    window.requestAnimationFrame(() => {
      els.board.scrollLeft = Math.max(0, els.boardStage.offsetLeft + ((area.x / 100) * els.boardStage.offsetWidth) - (els.board.clientWidth / 2));
      els.board.scrollTop = Math.max(0, els.boardStage.offsetTop + ((area.y / 100) * els.boardStage.offsetHeight) - (els.board.clientHeight / 2));
    });
  }

  function botActionReportGroups(messages) {
    const groups = [];
    let battle = null;

    messages.forEach((message) => {
      const battleStart = message.match(/^Battle board opened for (.+)\.$/);
      if (battleStart) {
        battle = { kind: "battle", area: battleStart[1], entries: [] };
        groups.push(battle);
        return;
      }

      if (battle && botReportEntryKind(message).battleDetail) {
        battle.entries.push(message);
        return;
      }

      battle = null;
      groups.push({ kind: "event", message });
    });

    return groups.length ? groups : [{ kind: "event", message: "Barbarian takes no action." }];
  }

  function botReportEntryKind(message) {
    if (/^Ariovistus special ability:/i.test(message)) return { key: "control", label: "Control", battleDetail: false };
    if (/\b(fires|rolled)\b/i.test(message)) return { key: "combat", label: "Combat", battleDetail: true };
    if (/\b(eliminated|wins the battle|holds .+ after battle|battle .+ continues|retreated)\b/i.test(message)) {
      return { key: "outcome", label: "Outcome", battleDetail: true };
    }
    if (/^Regroup victorious units/i.test(message)) return { key: "instruction", label: "Next", battleDetail: true };
    if (/\bjoins the (Roman|Barbarian) player\b/i.test(message) || /\b(Roman|Barbarian) (ally|allies)\b/i.test(message)) {
      return { key: "control", label: "Control", battleDetail: false };
    }
    if (/\b(moves|enters)\b/i.test(message)) return { key: "movement", label: "Move", battleDetail: false };
    if (/\bactivates\b/i.test(message)) return { key: "activation", label: "Activate", battleDetail: false };
    return { key: "event", label: "Event", battleDetail: false };
  }

  function botActionSummary(entry, revealedCard) {
    if (entry.startsWith("Barbarian activates ") && revealedCard?.includes("Revolt")) return { title: `Barbarian Action - Event: ${revealedCard}`, message: entry };
    if (/\bBarbarian (ally|allies)\.$/.test(entry)) return { title: "Barbarian Action - Neutral Tribe Activation", message: entry };
    if (entry.startsWith("Bot political action ")) return { title: "Barbarian Action - Political Action", message: entry.replace(/^Bot /, "Barbarian ") };
    if (entry.startsWith("Bot moves ")) return { title: "Barbarian Action - Movement", message: entry.replace(/^Bot /, "Barbarian ") };
    if (entry.startsWith("Bot Baggage Train ")) return { title: "Barbarian Action - Event: Baggage Train", message: entry.replace(/^Bot /, "Barbarian ") };
    if (entry.startsWith("Bot ") && revealedCard) return { title: `Barbarian Action - Event: ${revealedCard}`, message: entry.replace(/^Bot /, "Barbarian ") };
    return { title: "Barbarian Action", message: entry };
  }

  function resolveBotCard(card) {
    if (card.area && isNeutralArea(card.area) && state.botNeutralActivations < 2) {
      takeNeutralActivation(card.area, "barbarian");
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

    const effectiveTitle = card.title === "Massive Revolt"
      ? state.turn === 0 ? "Major Revolt" : "Massive Revolt"
      : card.title;
    if (effectiveTitle !== card.title) log(`Turn ${state.turn + 1}: ${card.title} is treated as a ${effectiveTitle}.`);
    activateArea(target, "barbarian");
    if (effectiveTitle === "Minor Revolt") return;

    if (effectiveTitle === "Massive Revolt") {
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
      const battleArea = await chooseBattleArea();
      if (battleArea === false) return;
      const mainOrigin = await chooseMainAttackingOrigin(battleArea);
      if (mainOrigin === false) return;
      const result = await postJson(`/game_sessions/${state.gameSessionId}/resolve_battles`, { state, area_id: battleArea, main_origin: mainOrigin });
      state = result.state;
      state.gameSessionId = result.game_session_id;
      normalizeLoadedState();
    } catch (error) {
      log(error.message);
    }
    render();
  }

  async function chooseBattleArea() {
    if (state.battle) return null;

    const areasToResolve = contestedAreas();
    if (areasToResolve.length <= 1) return areasToResolve[0] || null;

    return chooseBattleAreaWithDialog(areasToResolve);
  }

  async function chooseMainAttackingOrigin(areaId) {
    if (state.battle || !state.movement) return null;

    if (!areaId) return null;

    const origins = [...new Set(areaUnits(areaId)
      .filter((unit) => unit.owner === state.active)
      .map((unit) => movementEntry(unit, areaId))
      .filter((origin) => origin && origin !== areaId))];

    if (origins.length <= 1) return origins[0] || null;

    return chooseMainForceOnMap(areaId, origins);
  }

  function chooseBattleAreaWithDialog(areaIds) {
    return chooseOptionWithDialog({
      title: "Choose Battle",
      message: "Multiple battles are unresolved. Choose which battle to resolve first.",
      options: areaIds.map((areaId) => ({ value: areaId, label: areaName(areaId) }))
    });
  }

  function chooseOptionWithDialog({ title, message, options }) {
    if (!els.mainForceDialog) return false;

    return new Promise((resolve) => {
      let settled = false;
      const settle = (value) => {
        if (settled) return;
        settled = true;
        els.mainForceDialog.removeEventListener("cancel", onCancel);
        els.mainForceCancel.removeEventListener("click", onCancelClick);
        if (els.mainForceDialog.open) els.mainForceDialog.close();
        resolve(value);
      };
      const onCancel = (event) => {
        event.preventDefault();
        settle(false);
      };
      const onCancelClick = () => settle(false);

      els.mainForceTitle.textContent = title;
      els.mainForceMessage.textContent = message;
      els.mainForceChoices.innerHTML = "";
      options.forEach((option) => {
        const button = document.createElement("button");
        button.type = "button";
        button.textContent = option.label;
        button.addEventListener("click", () => settle(option.value));
        els.mainForceChoices.append(button);
      });
      els.mainForceDialog.addEventListener("cancel", onCancel);
      els.mainForceCancel.addEventListener("click", onCancelClick);
      if (els.resultDialog?.open) els.resultDialog.close();
      els.mainForceDialog.showModal();
    });
  }

  function chooseMainForceOnMap(areaId, origins) {
    return new Promise((resolve) => {
      let settled = false;
      const previousPiecesHidden = piecesHidden;
      const settle = (value) => {
        if (settled) return;
        settled = true;
        mainForceTargetDrag = null;
        els.mainForceTargetPanel?.classList.remove("is-dragging");
        mainForceSelection = null;
        piecesHidden = previousPiecesHidden;
        state.selectedUnit = null;
        state.selectedArea = null;
        render();
        resolve(value);
      };

      mainForceSelection = { areaId, origins, settle, panelPosition: null };
      piecesHidden = false;
      state.selectedUnit = null;
      state.selectedArea = areaId;
      els.selection.textContent = `Choose the main force attacking ${areaName(areaId)}.`;
      els.areaDetail.textContent = "Choose a highlighted origin area, or an outlined attacking unit. That group starts active; the others enter as reserves.";
      render();
      document.querySelector("#board")?.scrollIntoView({ block: "center", inline: "center" });
    });
  }

  function mainForceTargeting() {
    return Boolean(mainForceSelection && state.movement);
  }

  function mainForceOriginIds() {
    return mainForceTargeting() ? mainForceSelection.origins : [];
  }

  function mainForceEligible(unit) {
    return Boolean(
      mainForceTargeting() &&
      unit &&
      unit.owner === state.active &&
      unit.location === mainForceSelection.areaId &&
      mainForceSelection.origins.includes(movementEntry(unit, mainForceSelection.areaId))
    );
  }

  function chooseMainForceUnit(unitId) {
    const unit = state.units[unitId];
    if (!mainForceEligible(unit)) {
      els.selection.textContent = "Choose an outlined attacking unit or a highlighted entry area.";
      return;
    }

    chooseMainForceOrigin(movementEntry(unit, mainForceSelection.areaId));
  }

  function chooseMainForceOrigin(areaId) {
    if (!mainForceTargeting()) return;
    if (!mainForceSelection.origins.includes(areaId)) {
      els.selection.textContent = `${areaName(areaId)} is not an eligible main-force origin.`;
      els.areaDetail.textContent = "Choose one of the highlighted entry areas or an outlined attacking unit.";
      render();
      return;
    }

    mainForceSelection.settle(areaId);
  }

  function movementEntry(unit, areaId) {
    const moved = state.movement?.units?.[unit.id];
    if (!moved) return null;
    if (moved.entry) return moved.entry;

    const path = moved.path || [];
    const finalStep = [...path].reverse().find((step) => step.to === areaId);
    return finalStep?.from || moved.origin || null;
  }

  function battleFireResult(battle, unitId) {
    return [...(battle?.actionResults || [])].reverse().find((entry) => (
      entry.type === "fire" &&
      entry.unitId === unitId &&
      Number(entry.round || battle.round) === Number(battle.round)
    ));
  }

  function prepareDiceRollAnimation(battle, unitId, beforeRoll) {
    const result = battleFireResult(battle, unitId);
    if (!result?.rolls?.length || solitaireBotRoll(battle, unitId)) {
      resetDiceRollAnimation();
      return;
    }

    resetDiceRollAnimation();
    diceRollAnimation = {
      key: [battle.area, battle.round, unitId, result.rolls.join(",")].join(":"),
      unitId,
      rolling: true,
      displayRolls: result.rolls.map(() => randomDieFace()),
      beforeUnits: beforeRoll?.units || {},
      beforeHalfHits: beforeRoll?.halfHits || {},
      interval: null,
      settleTimer: null,
      soundTick: 0
    };
  }

  function diceAnimationRollingFor(battle, unitId) {
    if (!diceRollAnimation?.rolling || diceRollAnimation.unitId !== unitId) return false;
    const result = battleFireResult(battle, unitId);
    if (!result) return false;
    const key = [battle.area, battle.round, unitId, (result.rolls || []).join(",")].join(":");
    return diceRollAnimation.key === key;
  }

  function randomDieFace() {
    return Math.floor(Math.random() * 6) + 1;
  }

  function battleRollVisualSnapshot() {
    return {
      units: Object.fromEntries(Object.entries(state.units || {}).map(([id, unit]) => [id, {
        step: unit.step,
        location: unit.location
      }])),
      halfHits: { ...(state.battle?.halfHits || {}) }
    };
  }

  function startDiceRollAnimation() {
    if (!diceRollAnimation?.rolling || diceRollAnimation.interval || diceRollAnimation.settleTimer) return;

    playDiceClatter();
    diceRollAnimation.interval = window.setInterval(() => {
      if (!diceRollAnimation?.rolling) return;
      diceRollAnimation.displayRolls = diceRollAnimation.displayRolls.map(() => randomDieFace());
      document.querySelectorAll(`[data-battle-unit="${diceRollAnimation.unitId}"] .battle-roll-die`).forEach((die, index) => {
        die.textContent = diceRollAnimation.displayRolls[index];
      });
      diceRollAnimation.soundTick += 1;
      if (diceRollAnimation.soundTick % 2 === 0) playDiceClatter();
    }, 90);

    diceRollAnimation.settleTimer = window.setTimeout(() => {
      const unitId = diceRollAnimation?.unitId;
      if (!unitId || state.battle?.awaitingRollAcknowledgement !== unitId) {
        resetDiceRollAnimation();
        return;
      }
      window.clearInterval(diceRollAnimation.interval);
      diceRollAnimation.interval = null;
      diceRollAnimation.settleTimer = null;
      diceRollAnimation.rolling = false;
      playDiceSettle();
      render();
    }, 1050);
  }

  function resetDiceRollAnimation() {
    if (diceRollAnimation?.interval) window.clearInterval(diceRollAnimation.interval);
    if (diceRollAnimation?.settleTimer) window.clearTimeout(diceRollAnimation.settleTimer);
    diceRollAnimation = null;
  }

  function primeGameAudio() {
    try {
      const AudioContext = window.AudioContext || window.webkitAudioContext;
      if (!AudioContext) return;
      gameAudioContext ||= new AudioContext();
      if (gameAudioContext.state === "suspended") gameAudioContext.resume().catch(() => {});
    } catch (_error) {
      gameAudioContext = null;
    }
  }

  function playDiceClatter() {
    playDiceNoise({ duration: 0.045, volume: 0.045, frequency: 1050 + (Math.random() * 850) });
  }

  function playDiceSettle() {
    playDiceNoise({ duration: 0.075, volume: 0.075, frequency: 620 });
  }

  function playDiceNoise({ duration, volume, frequency }) {
    const context = gameAudioContext;
    if (!animatedDice || !context || context.state !== "running") return;

    try {
      const frameCount = Math.max(1, Math.floor(context.sampleRate * duration));
      const buffer = context.createBuffer(1, frameCount, context.sampleRate);
      const channel = buffer.getChannelData(0);
      for (let index = 0; index < frameCount; index += 1) {
        const decay = 1 - (index / frameCount);
        channel[index] = ((Math.random() * 2) - 1) * decay;
      }

      const source = context.createBufferSource();
      source.buffer = buffer;
      const filter = context.createBiquadFilter();
      filter.type = "bandpass";
      filter.frequency.value = frequency;
      filter.Q.value = 0.8;
      const gain = context.createGain();
      gain.gain.setValueAtTime(volume, context.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.001, context.currentTime + duration);
      source.connect(filter).connect(gain).connect(context.destination);
      source.start();
    } catch (_error) {
      // Battle play continues silently when Web Audio is unavailable.
    }
  }

  function playWoodenPieceTap() {
    if (!movementSounds) return;
    primeGameAudio();
    const context = gameAudioContext;
    if (!context) return;
    if (context.state === "suspended") {
      context.resume().then(() => emitWoodenPieceTap(context)).catch(() => {});
      return;
    }
    if (context.state !== "running") return;
    emitWoodenPieceTap(context);
  }

  function emitWoodenPieceTap(context) {
    try {
      const now = context.currentTime;
      const resonance = context.createOscillator();
      resonance.type = "triangle";
      resonance.frequency.setValueAtTime(500, now);
      resonance.frequency.exponentialRampToValueAtTime(330, now + 0.055);
      const resonanceGain = context.createGain();
      resonanceGain.gain.setValueAtTime(0.06, now);
      resonanceGain.gain.exponentialRampToValueAtTime(0.001, now + 0.06);
      resonance.connect(resonanceGain).connect(context.destination);

      const duration = 0.045;
      const frameCount = Math.max(1, Math.floor(context.sampleRate * duration));
      const buffer = context.createBuffer(1, frameCount, context.sampleRate);
      const channel = buffer.getChannelData(0);
      for (let index = 0; index < frameCount; index += 1) {
        const decay = Math.pow(1 - (index / frameCount), 2);
        channel[index] = ((Math.random() * 2) - 1) * decay;
      }
      const knock = context.createBufferSource();
      knock.buffer = buffer;
      const filter = context.createBiquadFilter();
      filter.type = "bandpass";
      filter.frequency.value = 900;
      filter.Q.value = 0.65;
      const knockGain = context.createGain();
      knockGain.gain.setValueAtTime(0.095, now);
      knockGain.gain.exponentialRampToValueAtTime(0.001, now + duration);
      knock.connect(filter).connect(knockGain).connect(context.destination);

      resonance.start(now);
      resonance.stop(now + 0.065);
      knock.start(now);
    } catch (_error) {
      // Movement remains available when browser audio is unavailable.
    }
  }

  async function battleAction(action, unitId = null, target = null) {
    const hadBattle = Boolean(state.battle);
    const previousBattleArea = state.battle?.area;
    const playedCard = currentActionCard();
    const wasRegrouping = state.regrouping;
    const wasRetreating = state.retreating;
    const beforeRoll = action === "fire" && animatedDice ? battleRollVisualSnapshot() : null;
    if (action === "fire" && animatedDice) primeGameAudio();
    try {
      await ensureGameSession();
      const result = await postJson(`/game_sessions/${state.gameSessionId}/battle_action`, {
        state,
        battle_action: action,
        unit_id: unitId,
        target
      });
      state = result.state;
      state.gameSessionId = result.game_session_id;
      normalizeLoadedState();
      if (action === "fire" && animatedDice && state.battle) {
        prepareDiceRollAnimation(state.battle, unitId, beforeRoll);
      } else if (action === "acknowledge_roll") {
        resetDiceRollAnimation();
      }
      if (previousBattleArea && state.battle?.area && state.battle.area !== previousBattleArea) {
        battleTransitionReview = {
          from: previousBattleArea,
          to: state.battle.area
        };
      }
      if (state.battle) {
        state.regrouping = Boolean(wasRegrouping && state.battle.phase === "regroup");
        state.retreating = Boolean(wasRetreating && state.battle.phase === "retreat");
      }
      if (hadBattle && !state.battle) {
        if (contestedAreas().length) await resolveBattles();
        else await discardSelectedCard(playedCard);
      }
    } catch (error) {
      log(error.message);
    }
    render();
    startDiceRollAnimation();
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
      if (unit.type === "roman") unit.eliminatedTurn = state.turn;
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

    if (state.endTurn) {
      renderWinterQuarters();
      renderRomanAdministration();
      return;
    }

    try {
      await ensureGameSession();
      const result = await postJson(`/game_sessions/${state.gameSessionId}/end_turn`, { state });
      state = result.state;
      state.gameSessionId = result.game_session_id;
      normalizeLoadedState();
      showCampaignResult();
    } catch (error) {
      log(`Turn could not be ended: ${error.message}`);
    }
    render();
  }

  async function completeEndTurn(event) {
    event.preventDefault();
    const selectedWinteringUnitIds = winteringUnitIds();
    setWinterQuartersError();

    try {
      await ensureGameSession();
      const result = await postJson(`/game_sessions/${state.gameSessionId}/end_turn`, {
        state,
        wintering_unit_ids: selectedWinteringUnitIds
      });
      state = result.state;
      state.gameSessionId = result.game_session_id;
      normalizeLoadedState();
      showCampaignResult();
      render();
    } catch (error) {
      setWinterQuartersError(error.message);
    }
  }

  async function completeRomanAdministration(event) {
    event.preventDefault();
    const phase = state.endTurn?.phase;
    if (!phase?.startsWith("roman")) return;
    setRomanAdministrationError();

    const payload = { state };
    if (phase === "romanReplacements") {
      payload.replacement_steps = state.endTurn.replacementSteps || {};
    } else if (phase === "romanSupplyProduction") {
      payload.supply_production_acknowledged = true;
    } else if (phase === "romanReinforcements") {
      payload.reinforcement_builds = state.endTurn.reinforcementBuilds || {};
    } else {
      return;
    }

    try {
      await ensureGameSession();
      const result = await postJson(`/game_sessions/${state.gameSessionId}/end_turn`, payload);
      state = result.state;
      state.gameSessionId = result.game_session_id;
      normalizeLoadedState();
      showCampaignResult();
      render();
    } catch (error) {
      setRomanAdministrationError(error.message);
    }
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
    renderYearlyObjectives();
    renderAreas();
    renderMovementArrows();
    renderLeaderHomeMarkers();
    renderTrackMarkers();
    renderPieces();
    renderNeutralActivationCards();
    renderHands();
    renderLog();
    renderModeControls();
    renderActionButtons();
    renderRevoltTargeting();
    renderVoluntaryRetreatTargeting();
    renderMainForceTargeting();
    renderUndoButton();
    renderPieceToggle();
    renderHandToggle();
    renderSidePanelToggle();
    renderBattleBoard();
    renderWinterQuarters();
    renderRomanAdministration();
    document.querySelectorAll(".player-button").forEach((button) => {
      button.classList.toggle("is-active", button.dataset.player === state.active);
    });
    renderCommittedCards();
    showBattleTransitionReview();
    showTurnAnnouncement();
    showBotActionReview();
  }

  function renderRevoltTargeting() {
    if (!els.revoltTargetPanel) return;
    const targeting = revoltTargeting();
    els.revoltTargetPanel.hidden = !targeting;
    if (!targeting) return;

    const count = revoltTargetSelection.unitIds.size;
    els.revoltTargetTitle.textContent = revoltTargetSelection.title;
    els.revoltTargetInstructions.textContent = `Choose 1 of ${count} highlighted tribe${count === 1 ? "" : "s"} on the map.`;
  }

  function renderVoluntaryRetreatTargeting() {
    if (!els.retreatTargetPanel) return;
    const targeting = voluntaryRetreatTargeting();
    els.retreatTargetPanel.hidden = !targeting;
    if (!targeting) return;

    const unit = state.units[voluntaryRetreatSelection.unitId];
    const targetNames = voluntaryRetreatSelection.targets.map(areaName).join(" or ");
    els.retreatTargetInstructions.textContent = `${unit.name}: choose ${targetNames} on the map.`;
  }

  function renderMainForceTargeting() {
    if (!els.mainForceTargetPanel) return;
    const targeting = mainForceTargeting();
    els.mainForceTargetPanel.hidden = !targeting;
    if (!targeting) return;

    els.mainForceTargetTitle.textContent = `Attack on ${areaName(mainForceSelection.areaId)}`;
    els.mainForceTargetInstructions.textContent = "Choose a highlighted origin or one of its outlined units.";
    const groups = mainForceSelection.origins.map((origin) => {
      const names = areaUnits(mainForceSelection.areaId)
        .filter((unit) => mainForceEligible(unit) && movementEntry(unit, mainForceSelection.areaId) === origin)
        .map((unit) => unit.name);
      return { origin, names };
    });

    els.mainForceTargetOptions.innerHTML = "";
    groups.forEach(({ origin, names }) => {
      const button = document.createElement("button");
      button.type = "button";
      const originName = document.createElement("strong");
      const unitNames = document.createElement("span");
      originName.textContent = areaName(origin);
      unitNames.textContent = names.join(", ");
      button.append(originName, unitNames);
      button.addEventListener("click", () => chooseMainForceOrigin(origin));
      els.mainForceTargetOptions.append(button);
    });

    positionMainForceTargetPanel();
  }

  function positionMainForceTargetPanel() {
    const panel = els.mainForceTargetPanel;
    const stage = els.boardStage;
    if (!panel || !stage || !mainForceTargeting()) return;

    const origins = mainForceSelection.origins.map((areaId) => areas[areaId]).filter(Boolean);
    const target = areas[mainForceSelection.areaId];
    if (!origins.length || !target) return;

    const stageWidth = stage.offsetWidth;
    const stageHeight = stage.offsetHeight;
    if (mainForceSelection.panelPosition) {
      setMainForceTargetPanelPosition(
        mainForceSelection.panelPosition.left,
        mainForceSelection.panelPosition.top
      );
      return;
    }
    const points = origins.map((area) => ({
      x: (area.x / 100) * stageWidth,
      y: (area.y / 100) * stageHeight
    }));
    const targetPoint = {
      x: (target.x / 100) * stageWidth,
      y: (target.y / 100) * stageHeight
    };
    const center = {
      x: points.reduce((sum, point) => sum + point.x, 0) / points.length,
      y: points.reduce((sum, point) => sum + point.y, 0) / points.length
    };
    const bounds = {
      left: Math.min(...points.map((point) => point.x)),
      right: Math.max(...points.map((point) => point.x)),
      top: Math.min(...points.map((point) => point.y)),
      bottom: Math.max(...points.map((point) => point.y))
    };
    const width = panel.offsetWidth;
    const height = panel.offsetHeight;
    const gap = 22;
    const inset = 10;
    const candidates = {
      left: { left: bounds.left - width - gap, top: center.y - (height / 2) },
      right: { left: bounds.right + gap, top: center.y - (height / 2) },
      above: { left: center.x - (width / 2), top: bounds.top - height - gap },
      below: { left: center.x - (width / 2), top: bounds.bottom + gap }
    };
    const horizontalAttack = Math.abs(targetPoint.x - center.x) > Math.abs(targetPoint.y - center.y);
    const preferredSide = horizontalAttack
      ? (targetPoint.x >= center.x ? "left" : "right")
      : (center.x >= stageWidth / 2 ? "left" : "right");
    const order = [preferredSide, preferredSide === "left" ? "right" : "left", "above", "below"];
    const fits = ({ left, top }) => (
      left >= inset && top >= inset && left + width <= stageWidth - inset && top + height <= stageHeight - inset
    );
    const chosen = candidates[order.find((side) => fits(candidates[side]))] || candidates[preferredSide];

    setMainForceTargetPanelPosition(chosen.left, chosen.top);
  }

  function setMainForceTargetPanelPosition(left, top, { remember = false } = {}) {
    const panel = els.mainForceTargetPanel;
    const stage = els.boardStage;
    if (!panel || !stage) return;

    const inset = 10;
    const clampedLeft = Math.max(inset, Math.min(left, stage.offsetWidth - panel.offsetWidth - inset));
    const clampedTop = Math.max(inset, Math.min(top, stage.offsetHeight - panel.offsetHeight - inset));
    panel.style.left = `${clampedLeft}px`;
    panel.style.top = `${clampedTop}px`;
    if (remember && mainForceSelection) {
      mainForceSelection.panelPosition = { left: clampedLeft, top: clampedTop };
    }
  }

  function beginMainForceTargetDrag(event) {
    const panel = els.mainForceTargetPanel;
    if (event.button !== 0 || !panel || !mainForceTargeting()) return;
    mainForceTargetDrag = {
      pointerId: event.pointerId,
      startX: event.clientX,
      startY: event.clientY,
      startLeft: panel.offsetLeft,
      startTop: panel.offsetTop
    };
    event.currentTarget.setPointerCapture(event.pointerId);
    panel.classList.add("is-dragging");
    event.preventDefault();
  }

  function moveMainForceTargetPanel(event) {
    if (!mainForceTargetDrag || event.pointerId !== mainForceTargetDrag.pointerId) return;
    setMainForceTargetPanelPosition(
      mainForceTargetDrag.startLeft + event.clientX - mainForceTargetDrag.startX,
      mainForceTargetDrag.startTop + event.clientY - mainForceTargetDrag.startY,
      { remember: true }
    );
  }

  function endMainForceTargetDrag(event) {
    if (!mainForceTargetDrag || event.pointerId !== mainForceTargetDrag.pointerId) return;
    mainForceTargetDrag = null;
    els.mainForceTargetPanel?.classList.remove("is-dragging");
  }

  function renderStatus() {
    document.querySelector("#mode-label").textContent = modeName();
    document.querySelector("#turn-label").textContent = gameData.years[state.turn];
    document.querySelector("#phase-label").textContent = phaseStatusLabel();
    document.querySelector("#active-label").textContent = playerName(state.active);
    document.querySelector("#supply-label").textContent = state.supply;
    document.querySelector("#vp-label").textContent = state.vp;
    const objectivesEnabled = Boolean(state.options?.yearlyObjectives);
    const historicalReinforcementsEnabled = Boolean(state.options?.historicalReinforcements);
    const postGameReportEnabled = Boolean(state.options?.postGameReport);
    const setupLocked = optionalRulesLocked();
    els.playMode.value = state.mode;
    els.playModeButtons.forEach((button) => {
      button.setAttribute("aria-pressed", String(button.dataset.playMode === state.mode));
    });
    if (els.modeMenu) {
      els.modeMenu.hidden = setupLocked;
      if (setupLocked) els.modeMenu.removeAttribute("open");
    }
    if (els.yearlyObjectives) {
      const locked = setupLocked;
      els.yearlyObjectives.checked = objectivesEnabled;
      els.yearlyObjectives.disabled = locked;
      els.yearlyObjectives.closest("label")?.setAttribute(
        "title",
        locked ? "Historical Objectives are fixed after the first card is played" : "Apply the optional Yearly Objectives victory-point schedule"
      );
    }
    if (els.historicalReinforcements) {
      els.historicalReinforcements.checked = historicalReinforcementsEnabled;
      els.historicalReinforcements.disabled = setupLocked;
      els.historicalReinforcementsToggle?.setAttribute(
        "title",
        setupLocked ? "Historical Reinforcements are fixed after the first card is played" : "Use the historical Roman reinforcement schedule printed on the turn track"
      );
    }
    if (els.postGameReport) {
      els.postGameReport.checked = postGameReportEnabled;
      els.postGameReport.disabled = setupLocked;
      els.postGameReportToggle?.setAttribute(
        "title",
        setupLocked ? "Post-game report generation is fixed after the first card is played" : "Write a narrative HTML session report after a complete eight-turn campaign"
      );
    }
    if (els.animatedDice) {
      els.animatedDice.checked = animatedDice;
    }
    if (els.movementSounds) {
      els.movementSounds.checked = movementSounds;
    }
    if (els.movementArrows) {
      els.movementArrows.checked = movementArrows;
    }
    if (els.optionalRulesStatus && els.optionalRulesLabel) {
      const enabledOptions = [];
      if (objectivesEnabled) enabledOptions.push("Historical Objectives");
      if (historicalReinforcementsEnabled) enabledOptions.push("Historical Reinforcements");
      if (postGameReportEnabled) enabledOptions.push("Post-game Report");
      els.optionalRulesStatus.hidden = enabledOptions.length === 0;
      els.optionalRulesLabel.textContent = enabledOptions.join(" · ");
    }
    if (els.finishRegroup) {
      els.finishRegroup.hidden = !battleMapMode();
      els.finishRegroup.textContent = state.retreating ? "Retreat Complete" : "Finished Regroup";
    }
  }

  function phaseStatusLabel() {
    if (state.phase !== "Card Phase") return state.phase;

    const romanCards = state.hands?.roman?.length || 0;
    const cardsRemaining = state.mode === "hotseat"
      ? Math.max(romanCards, state.hands?.barbarian?.length || 0)
      : romanCards;
    const cardPlay = Math.min(5, Math.max(1, 6 - cardsRemaining));

    return `${state.phase} / ${cardPlay}`;
  }

  function renderYearlyObjectives() {
    const enabled = Boolean(state.options?.yearlyObjectives);
    if (!els.yearlyObjectivesPanel) return;

    els.yearlyObjectivesPanel.hidden = !enabled;
    if (!enabled) return;

    const campaign = gameData.yearlyObjectives?.[state.turn];
    if (!campaign) return;

    els.objectiveTitle.textContent = campaign.title;
    els.objectiveYear.textContent = gameData.years[state.turn];
    els.objectiveList.innerHTML = campaign.objectives.map((objective) => `
      <li class="objective-${objective.vp > 0 ? "gain" : "loss"}">
        <span>${objective.text}</span>
        <strong>${objective.vp > 0 ? "+" : ""}${objective.vp} VP</strong>
      </li>
    `).join("");
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
      if (!areaId) return;
      if (mainForceTargeting()) chooseMainForceOrigin(areaId);
      else if (voluntaryRetreatTargeting()) chooseVoluntaryRetreatTarget(areaId);
      else if (revoltTargeting()) chooseRevoltTargetArea(areaId);
      else moveSelectedTo(areaId);
    });
    els.areaLayer.append(clickCatcher);

    const territoryOverlay = areaTerritoryOverlay();
    if (territoryOverlay) {
      const overlay = document.createElementNS("http://www.w3.org/2000/svg", "image");
      overlay.setAttribute("x", 0);
      overlay.setAttribute("y", 0);
      overlay.setAttribute("width", 100);
      overlay.setAttribute("height", 100);
      overlay.setAttribute("preserveAspectRatio", "none");
      overlay.setAttribute("href", territoryOverlay);
      overlay.setAttribute("pointer-events", "none");
      overlay.classList.add("area-territory-overlay");
      els.areaLayer.append(overlay);
      return;
    }

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
      marker.classList.toggle("is-targeting", targetingPoliticalAction());
      marker.classList.toggle("is-revolt-target", revoltTargeting() && revoltTargetAreaIds().includes(area.id));
      marker.classList.toggle("is-retreat-target", voluntaryRetreatTargetAreaIds().includes(area.id));
      marker.classList.toggle("is-main-force-target", mainForceOriginIds().includes(area.id));
      marker.classList.toggle(
        "is-politically-controlled",
        targetingPoliticalAction() && activePlayerControlsPoliticalArea(area.id)
      );
      marker.classList.toggle(
        `owner-${state.active}`,
        targetingPoliticalAction() && activePlayerControlsPoliticalArea(area.id)
      );
      marker.classList.toggle(
        "is-targeting-disabled",
        targetingPoliticalAction() && state.active === "roman" && Boolean(romanSpecialTargetBlockReason(area.id, "political action"))
      );
      marker.classList.toggle("is-drag-target", state.dragArea === area.id);
      els.areaLayer.append(marker);
    });
  }

  function areaTerritoryOverlay() {
    const territories = areaHitMap?.territories;
    if (!territories) return null;

    const styles = territories.ids.map((areaId) => areaHighlightStyle(areas[areaId]));
    if (!styles.some(Boolean)) return null;
    const signature = styles.map((style, index) => style ? `${territories.ids[index]}:${style.name}` : "").join("|");
    if (areaOverlayCache.has(signature)) return areaOverlayCache.get(signature);

    const canvas = document.createElement("canvas");
    canvas.width = areaHitMap.width;
    canvas.height = areaHitMap.height;
    const context = canvas.getContext("2d");
    const overlay = context.createImageData(canvas.width, canvas.height);
    const pixels = overlay.data;
    const territoryLabels = territories.labels;

    for (let index = 0; index < territoryLabels.length; index += 1) {
      const territoryIndex = territoryLabels[index];
      const style = styles[territoryIndex];
      if (!style) continue;

      const edge = territoryPixelIsEdge(territoryLabels, canvas.width, canvas.height, index, territoryIndex);
      const x = index % canvas.width;
      const y = Math.floor(index / canvas.width);
      const stripe = style.stripe && ((x - y + canvas.height) % 22 < 6);
      const color = edge ? style.edge : (stripe ? style.stripe : style.fill);
      const pixelIndex = index * 4;
      pixels[pixelIndex] = color[0];
      pixels[pixelIndex + 1] = color[1];
      pixels[pixelIndex + 2] = color[2];
      pixels[pixelIndex + 3] = color[3];
    }

    context.putImageData(overlay, 0, 0);
    const image = canvas.toDataURL("image/png");
    if (areaOverlayCache.size >= 24) areaOverlayCache.delete(areaOverlayCache.keys().next().value);
    areaOverlayCache.set(signature, image);
    return image;
  }

  function territoryPixelIsEdge(labels, width, height, index, territoryIndex) {
    const x = index % width;
    const y = Math.floor(index / width);

    return territoryEdgeDirections.some(([dx, dy]) => {
      for (let radius = 1; radius <= 3; radius += 1) {
        const nextX = x + (dx * radius);
        const nextY = y + (dy * radius);
        if (nextX < 0 || nextY < 0 || nextX >= width || nextY >= height) break;
        const neighboringTerritory = labels[(nextY * width) + nextX];
        if (neighboringTerritory >= 0 && neighboringTerritory !== territoryIndex) return true;
      }
      return false;
    });
  }

  function areaHighlightStyle(area) {
    if (!area || area.sea) return null;
    const targeting = targetingPoliticalAction();
    const blocked = targeting && state.active === "roman" && Boolean(romanSpecialTargetBlockReason(area.id, "political action"));

    if (state.dragArea === area.id) {
      return { name: "drag", fill: [255, 224, 116, 68], edge: [255, 235, 158, 220] };
    }
    if (blocked) {
      return { name: "disabled", fill: [104, 102, 94, 28], edge: [142, 138, 126, 125] };
    }
    if (revoltTargeting() && revoltTargetAreaIds().includes(area.id)) {
      return {
        name: "revolt-target",
        fill: [217, 180, 95, 66],
        stripe: [139, 88, 42, 96],
        edge: [255, 231, 145, 245]
      };
    }
    if (voluntaryRetreatTargetAreaIds().includes(area.id)) {
      return {
        name: "retreat-target",
        fill: [91, 171, 205, 76],
        stripe: [46, 112, 148, 108],
        edge: [170, 229, 255, 248]
      };
    }
    if (mainForceOriginIds().includes(area.id)) {
      return {
        name: "main-force-target",
        fill: [91, 171, 205, 58],
        edge: [170, 229, 255, 248]
      };
    }
    if (targeting && activePlayerControlsPoliticalArea(area.id)) {
      return state.active === "roman"
        ? {
            name: "political-control-roman",
            fill: [217, 107, 85, 74],
            stripe: [137, 42, 32, 128],
            edge: [255, 151, 120, 245]
          }
        : {
            name: "political-control-barbarian",
            fill: [118, 168, 110, 74],
            stripe: [42, 91, 43, 128],
            edge: [170, 230, 157, 245]
          };
    }
    if (targeting) {
      return { name: "targeting", fill: [255, 230, 140, 34], edge: [255, 230, 140, 160] };
    }
    if (state.selectedArea === area.id) {
      return { name: "selected", fill: [255, 230, 140, 35], edge: [255, 235, 158, 195] };
    }
    if (movementAreaActivated(area.id)) {
      return { name: "movement", fill: [72, 190, 145, 34], edge: [72, 220, 155, 145] };
    }
    return null;
  }

  function renderMovementArrows() {
    if (!els.movementArrowLayer) return;
    els.movementArrowLayer.innerHTML = "";
    if (retreatArrowMode()) {
      renderRetreatArrows();
      return;
    }
    if (!movementArrows) return;
    if (state.battle?.phase === "regroup") return;
    const reviewingBotMovement = currentBotActionReviewStage()?.kind === "movement";
    if ((!state.movement && !reviewingBotMovement) || piecesHidden) return;

    const routes = reviewingBotMovement ? botActionReview.movementRoutes : battleEntryRoutes();
    if (!routes.length) return;

    const definitions = document.createElementNS("http://www.w3.org/2000/svg", "defs");
    ["roman", "barbarian"].forEach((owner) => {
      appendMovementArrowMarker(definitions, owner, { outline: true });
      appendMovementArrowMarker(definitions, owner);
    });
    els.movementArrowLayer.append(definitions);

    const preparedRoutes = routes.map((route) => ({ route, points: entryArrowRoutePoints(route) }));
    spaceMovementArrowOrigins(preparedRoutes);

    preparedRoutes.forEach(({ route, points }) => {
      const from = areas[route.from];
      const to = areas[route.to];
      const hooked = entryArrowShouldHook(route, points);
      const start = points[0];
      const group = document.createElementNS("http://www.w3.org/2000/svg", "g");
      const unitLabel = `${route.count} ${playerName(route.owner)} unit${route.count === 1 ? "" : "s"}`;
      group.classList.add("movement-entry-arrow", `owner-${route.owner}`);
      if (route.forceMarch) group.classList.add("is-force-march");
      const routeDescription = `${unitLabel} entered ${areaName(route.to)} from ${areaName(route.from)}${route.forceMarch ? " by forced march" : ""}.`;
      group.setAttribute("role", "img");
      group.setAttribute("aria-label", routeDescription);

      const title = document.createElementNS("http://www.w3.org/2000/svg", "title");
      title.textContent = routeDescription;
      group.append(title);

      const outline = entryArrowPath(points, "movement-entry-arrow-outline", { hooked });
      const line = entryArrowPath(points, "movement-entry-arrow-line", { hooked });
      const accent = entryArrowPath(points, "movement-entry-arrow-accent", { hooked });
      outline.setAttribute("marker-end", `url(#movement-arrowhead-outline-${route.owner})`);
      line.setAttribute("marker-end", `url(#movement-arrowhead-${route.owner})`);
      const originOutline = entryArrowOrigin(start, "movement-entry-arrow-origin-outline", 1.04);
      const origin = entryArrowOrigin(start, "movement-entry-arrow-origin", 0.82);
      group.append(outline, line, accent, originOutline, origin);
      els.movementArrowLayer.append(group);
    });
  }

  function retreatArrowMode() {
    return retreatingOnMap() || voluntaryRetreatTargeting();
  }

  function retreatArrowRoutes() {
    const battle = state.battle;
    if (!battle || !retreatArrowMode()) return [];

    let units;
    if (voluntaryRetreatTargeting()) {
      units = [state.units[voluntaryRetreatSelection.unitId]].filter(Boolean);
    } else {
      const selected = state.units[state.selectedUnit];
      units = canForcedRetreatUnit(selected) ? [selected] : forcedRetreatUnits(battle);
    }

    const routes = new Map();
    units.forEach((unit) => {
      legalVoluntaryRetreatTargets(battle, unit).forEach((target) => {
        const route = routes.get(target) || { from: battle.area, to: target, unitNames: [] };
        route.unitNames.push(unit.name);
        routes.set(target, route);
      });
    });
    return [...routes.values()];
  }

  function renderRetreatArrows() {
    const routes = retreatArrowRoutes();
    if (!routes.length) return;

    const definitions = document.createElementNS("http://www.w3.org/2000/svg", "defs");
    appendRetreatArrowMarker(definitions, { outline: true });
    appendRetreatArrowMarker(definitions);
    els.movementArrowLayer.append(definitions);

    routes.forEach((route) => {
      const border = battleEntryBorderPoint(route.from, route.to);
      const start = entryArrowPoint(areas[route.from], border, 0.38);
      const end = entryArrowPoint(border, areas[route.to], 0.34);
      const description = `${route.unitNames.join(", ")} may retreat from ${areaName(route.from)} to ${areaName(route.to)}.`;
      const group = document.createElementNS("http://www.w3.org/2000/svg", "g");
      group.classList.add("retreat-path-arrow");
      group.setAttribute("role", "img");
      group.setAttribute("aria-label", description);

      const title = document.createElementNS("http://www.w3.org/2000/svg", "title");
      title.textContent = description;
      group.append(title);

      const outline = simpleArrowPath(start, end, "retreat-path-arrow-outline");
      const line = simpleArrowPath(start, end, "retreat-path-arrow-line");
      outline.setAttribute("marker-end", "url(#retreat-arrowhead-outline)");
      line.setAttribute("marker-end", "url(#retreat-arrowhead)");
      group.append(outline, line);
      els.movementArrowLayer.append(group);
    });
  }

  function simpleArrowPath(start, end, className) {
    const path = document.createElementNS("http://www.w3.org/2000/svg", "path");
    path.setAttribute("d", `M ${start.x.toFixed(3)} ${start.y.toFixed(3)} L ${end.x.toFixed(3)} ${end.y.toFixed(3)}`);
    path.classList.add(className);
    return path;
  }

  function appendRetreatArrowMarker(definitions, { outline = false } = {}) {
    const marker = document.createElementNS("http://www.w3.org/2000/svg", "marker");
    marker.id = outline ? "retreat-arrowhead-outline" : "retreat-arrowhead";
    marker.setAttribute("viewBox", "0 0 10 10");
    marker.setAttribute("preserveAspectRatio", "none");
    marker.setAttribute("refX", "8.4");
    marker.setAttribute("refY", "5");
    marker.setAttribute("markerUnits", "userSpaceOnUse");
    marker.setAttribute("markerWidth", outline ? "1.72" : "1.48");
    marker.setAttribute("markerHeight", outline ? "2.15" : "1.85");
    marker.setAttribute("orient", "auto-start-reverse");

    const arrowhead = document.createElementNS("http://www.w3.org/2000/svg", "path");
    arrowhead.setAttribute("d", "M 0 0 L 10 5 L 0 10 z");
    arrowhead.classList.add(outline ? "retreat-arrowhead-outline" : "retreat-arrowhead-fill");
    marker.append(arrowhead);
    definitions.append(marker);
  }

  function spaceMovementArrowOrigins(preparedRoutes) {
    const groups = new Map();
    preparedRoutes.forEach((prepared) => {
      if (!groups.has(prepared.route.from)) groups.set(prepared.route.from, []);
      groups.get(prepared.route.from).push(prepared);
    });

    groups.forEach((group) => {
      if (group.length < 2) return;
      const center = group.reduce((point, prepared) => ({
        x: point.x + (prepared.points[0].x / group.length),
        y: point.y + (prepared.points[0].y / group.length)
      }), { x: 0, y: 0 });
      const direction = group.reduce((vector, prepared) => {
        const next = prepared.points[1] || prepared.points.at(-1);
        const dx = next.x - prepared.points[0].x;
        const dy = (next.y - prepared.points[0].y) * mapAspectRatio;
        const length = Math.hypot(dx, dy) || 1;
        return { x: vector.x + (dx / length), y: vector.y + (dy / length) };
      }, { x: 0, y: 0 });
      const directionLength = Math.hypot(direction.x, direction.y) || 1;
      const perpendicular = {
        x: -(direction.y / directionLength),
        y: (direction.x / directionLength) / mapAspectRatio
      };

      group.forEach((prepared, index) => {
        const offset = (index - ((group.length - 1) / 2)) * 2.4;
        prepared.points[0] = {
          x: center.x + (perpendicular.x * offset),
          y: center.y + (perpendicular.y * offset)
        };
      });
    });
  }

  function appendMovementArrowMarker(definitions, owner, { outline = false } = {}) {
    const marker = document.createElementNS("http://www.w3.org/2000/svg", "marker");
    const outlineLabel = outline ? "-outline" : "";
    marker.id = `movement-arrowhead${outlineLabel}-${owner}`;
    marker.setAttribute("viewBox", "0 0 10 10");
    marker.setAttribute("preserveAspectRatio", "none");
    marker.setAttribute("refX", "8.35");
    marker.setAttribute("refY", "5");
    marker.setAttribute("markerUnits", "userSpaceOnUse");
    marker.setAttribute("markerWidth", outline ? "2.28" : "2.05");
    marker.setAttribute("markerHeight", outline ? "3.1" : "2.8");
    marker.setAttribute("orient", "auto-start-reverse");

    const arrowhead = document.createElementNS("http://www.w3.org/2000/svg", "path");
    arrowhead.setAttribute("d", "M 0 0 L 10 5 L 0 10 z");
    arrowhead.classList.add(`movement-arrowhead-${outline ? "outline" : "fill"}-${owner}`);
    marker.append(arrowhead);
    definitions.append(marker);
  }

  function battleEntryRoutes() {
    const battleAreas = new Set(contestedAreas());
    if (state.battle?.area) battleAreas.add(state.battle.area);
    const routes = new Map();

    battleAreas.forEach((areaId) => {
      const currentBattle = state.battle?.area === areaId ? state.battle : null;
      const unitIds = currentBattle
        ? [...(currentBattle.attackers || []), ...(currentBattle.defenders || [])]
        : areaUnits(areaId).map((unit) => unit.id);

      unitIds.forEach((unitId) => {
        const unit = state.units[unitId];
        const moved = state.movement?.units?.[unitId];
        if (!unit || !moved) return;
        const entry = currentBattle?.entries?.[unitId] || movementEntry(unit, areaId);
        const forceMarch = movementUsedForceMarch(moved);
        const path = forceMarch ? movementAreaPath(moved, areaId) : [entry, areaId];
        const origin = path[0];
        if (!origin || origin === areaId || path.some((areaKey) => !areas[areaKey])) return;
        if (path.slice(0, -1).some((areaKey, index) => !areas[areaKey]?.links?.includes(path[index + 1]))) return;

        const key = `${unit.owner}:${path.join("->")}`;
        const route = routes.get(key) || { owner: unit.owner, from: origin, to: areaId, path, count: 0, forceMarch: false };
        route.count += 1;
        route.forceMarch ||= forceMarch;
        routes.set(key, route);
      });
    });

    return [...routes.values()];
  }

  function entryArrowPoint(from, to, progress) {
    return {
      x: from.x + ((to.x - from.x) * progress),
      y: from.y + ((to.y - from.y) * progress)
    };
  }

  function movementUsedForceMarch(moved) {
    return Boolean(moved?.force || (!moved?.naval && Number(moved?.steps) >= 2 && (moved?.path || []).length >= 2));
  }

  function movementAreaPath(moved, destination) {
    const steps = moved?.path || [];
    const path = [moved?.origin || steps[0]?.from].filter(Boolean);
    steps.forEach((step) => {
      if (step?.to && path.at(-1) !== step.to) path.push(step.to);
    });
    if (path.at(-1) !== destination) path.push(destination);
    return path;
  }

  function entryArrowRoutePoints(route) {
    const areaPath = route.path?.length > 1 ? route.path : [route.from, route.to];
    const firstBorder = battleEntryBorderPoint(areaPath[0], areaPath[1]);
    const points = [entryArrowPoint(areas[areaPath[0]], firstBorder, 0.08)];

    areaPath.slice(0, -1).forEach((areaKey, index) => {
      const nextAreaKey = areaPath[index + 1];
      points.push(battleEntryBorderPoint(areaKey, nextAreaKey));
      if (index < areaPath.length - 2) points.push(areas[nextAreaKey]);
    });

    const finalBorder = points.at(-1);
    points.push(entryArrowPoint(finalBorder, areas[route.to], 0.38));
    return points;
  }

  function entryArrowShouldHook(route, points) {
    if (route.forceMarch || route.path?.length > 2) return false;
    const start = points[0];
    const end = points.at(-1);
    const horizontalDistance = Math.abs(end.x - start.x);
    const verticalDistance = Math.abs(end.y - start.y);
    return horizontalDistance >= 4 && verticalDistance >= 8 && verticalDistance > horizontalDistance * 0.8;
  }

  function entryArrowPath(points, className, { hooked = false } = {}) {
    const path = document.createElementNS("http://www.w3.org/2000/svg", "path");
    if (hooked) {
      path.setAttribute("d", hookedEntryArrowPath(points[0], points.at(-1)));
      path.classList.add(className);
      return path;
    }

    const commands = [`M ${points[0].x.toFixed(3)} ${points[0].y.toFixed(3)}`];
    points.slice(0, -1).forEach((point, index) => {
      const previous = points[Math.max(0, index - 1)];
      const next = points[index + 1];
      const afterNext = points[Math.min(points.length - 1, index + 2)];
      const firstControl = {
        x: point.x + ((next.x - previous.x) / 6),
        y: point.y + ((next.y - previous.y) / 6)
      };
      const secondControl = {
        x: next.x - ((afterNext.x - point.x) / 6),
        y: next.y - ((afterNext.y - point.y) / 6)
      };
      commands.push(`C ${firstControl.x.toFixed(3)} ${firstControl.y.toFixed(3)} ${secondControl.x.toFixed(3)} ${secondControl.y.toFixed(3)} ${next.x.toFixed(3)} ${next.y.toFixed(3)}`);
    });
    path.setAttribute("d", commands.join(" "));
    path.classList.add(className);
    return path;
  }

  function hookedEntryArrowPath(start, end) {
    const horizontalDirection = Math.sign(end.x - start.x) || 1;
    const verticalDirection = Math.sign(end.y - start.y) || -1;
    const horizontalDistance = Math.abs(end.x - start.x);
    const verticalDistance = Math.abs(end.y - start.y);
    const finalApproach = Math.min(5, verticalDistance * 0.34);
    const curveLateral = Math.min(6.5, horizontalDistance * 0.65);
    const curveRise = Math.min(2.6, horizontalDistance * 0.28);
    const verticalJoin = {
      x: end.x,
      y: end.y - (verticalDirection * finalApproach)
    };
    const curveControl = {
      x: end.x,
      y: verticalJoin.y - (verticalDirection * Math.min(2.4, finalApproach * 0.5))
    };
    const diagonalEnd = {
      x: curveControl.x - (horizontalDirection * curveLateral),
      y: curveControl.y - (verticalDirection * curveRise * mapAspectRatio)
    };
    return [
      `M ${start.x.toFixed(3)} ${start.y.toFixed(3)}`,
      `L ${diagonalEnd.x.toFixed(3)} ${diagonalEnd.y.toFixed(3)}`,
      `Q ${curveControl.x.toFixed(3)} ${curveControl.y.toFixed(3)} ${verticalJoin.x.toFixed(3)} ${verticalJoin.y.toFixed(3)}`,
      `L ${end.x.toFixed(3)} ${end.y.toFixed(3)}`
    ].join(" ");
  }

  function entryArrowOrigin(point, className, radius) {
    const mapAspectRatio = (els.boardImage?.naturalWidth && els.boardImage?.naturalHeight)
      ? els.boardImage.naturalWidth / els.boardImage.naturalHeight
      : 1;
    const origin = document.createElementNS("http://www.w3.org/2000/svg", "ellipse");
    origin.setAttribute("cx", point.x.toFixed(3));
    origin.setAttribute("cy", point.y.toFixed(3));
    origin.setAttribute("rx", radius.toFixed(3));
    origin.setAttribute("ry", (radius * mapAspectRatio).toFixed(3));
    origin.classList.add(className);
    return origin;
  }

  function areaPairKey(left, right) {
    return [left, right].sort().join("<->");
  }

  function battleEntryBorderPoint(fromAreaId, toAreaId) {
    const detected = areaHitMap?.borderPoints?.get(areaPairKey(fromAreaId, toAreaId));
    if (detected) return detected;

    const from = areas[fromAreaId];
    const to = areas[toAreaId];
    const midpoint = entryArrowPoint(from, to, 0.5);
    const commonNeighbors = (from.links || [])
      .filter((areaId) => areaId !== fromAreaId && areaId !== toAreaId && to.links?.includes(areaId))
      .map((areaId) => areas[areaId])
      .filter(Boolean);
    if (!commonNeighbors.length) return midpoint;

    const neighborCenter = commonNeighbors.reduce((center, area) => ({
      x: center.x + (area.x / commonNeighbors.length),
      y: center.y + (area.y / commonNeighbors.length)
    }), { x: 0, y: 0 });
    const awayX = midpoint.x - neighborCenter.x;
    const awayY = (midpoint.y - neighborCenter.y) * mapAspectRatio;
    const distance = Math.hypot(awayX, awayY);
    if (!distance) return midpoint;

    const offset = 3;
    return {
      x: midpoint.x + ((awayX / distance) * offset),
      y: midpoint.y + (((awayY / distance) * offset) / mapAspectRatio)
    };
  }

  function renderTrackMarkers() {
    els.trackMarkerLayer.innerHTML = "";
    if (piecesHidden) return;

    const vp = Math.max(0, state.vp || 0);
    const tribes = controlledTribes();
    const markers = [
      {
        image: gameData.markers.roman_supply,
        label: `Roman Supply: ${state.supply}`,
        position: recordTrackPosition(state.supply)
      },
      {
        image: gameData.markers.tribes_controlled,
        label: `Tribes Controlled: ${tribes}`,
        position: recordTrackPosition(tribes)
      },
      {
        image: gameData.markers.roman_vp_x1,
        label: `Roman VP ×1: ${vp % 10}`,
        position: recordTrackPosition(vp % 10)
      },
      {
        image: gameData.markers.roman_vp_x10,
        label: `Roman VP ×10: ${Math.min(Math.floor(vp / 10), 9)}`,
        position: recordTrackPosition(Math.min(Math.floor(vp / 10), 9))
      },
      {
        image: gameData.markers.turn,
        label: `Turn: ${gameData.years[state.turn]}`,
        position: turnTrackPosition(state.turn),
        turn: true
      }
    ];

    const markerGroups = new Map();
    markers.forEach((marker) => {
      const key = `${marker.position.x}:${marker.position.y}`;
      if (!markerGroups.has(key)) markerGroups.set(key, []);
      markerGroups.get(key).push(marker);
    });

    markerGroups.forEach((group) => {
      const stack = document.createElement("div");
      const multiple = group.length > 1;
      const labels = group.map((marker) => marker.label);
      stack.className = `track-marker-stack${group.some((marker) => marker.turn) ? " turn-marker-stack" : ""}${multiple ? " has-multiple" : ""}`;
      stack.style.left = `${group[0].position.x}%`;
      stack.style.top = `${group[0].position.y}%`;
      stack.setAttribute("role", "img");
      stack.setAttribute("aria-label", labels.join("; "));

      if (multiple) {
        stack.tabIndex = 0;
      } else {
        stack.title = labels[0];
      }

      group.forEach((marker, index) => {
        const fan = trackMarkerFan(index, group.length);
        const image = document.createElement("img");
        image.className = "track-marker";
        image.src = marker.image;
        image.alt = "";
        image.style.setProperty("--marker-fan-x", `${fan.x}%`);
        image.style.setProperty("--marker-fan-y", `${fan.y}%`);
        image.style.setProperty("--marker-rotation", `${fan.rotation}deg`);
        image.style.setProperty("--marker-expanded-x", `${fan.expandedX}%`);
        image.style.setProperty("--marker-expanded-y", `${fan.expandedY}%`);
        image.style.setProperty("--marker-expanded-rotation", `${fan.expandedRotation}deg`);
        stack.append(image);
      });

      els.trackMarkerLayer.append(stack);
    });
  }

  function renderLeaderHomeMarkers() {
    if (!els.leaderHomeMarkerLayer) return;
    els.leaderHomeMarkerLayer.innerHTML = "";
    if (piecesHidden) return;

    [
      { unitId: "ambiorix", image: gameData.markers.ambiorix_home },
      { unitId: "dumnorix", image: gameData.markers.dumnorix_home }
    ].forEach(({ unitId, image }) => {
      const leader = state.units?.[unitId];
      const area = areas[leader?.home];
      const inPlay = leader && ![null, undefined, "offboard", "eliminated"].includes(leader.location);
      if (!inPlay || !area || !image) return;

      const position = leaderHomeMarkerPosition(area);

      const marker = document.createElement("div");
      marker.className = `leader-home-marker is-${unitId}`;
      marker.style.left = `${position.x}%`;
      marker.style.top = `${position.y}%`;
      marker.title = `${leader.name} home area: ${area.name}`;
      marker.setAttribute("role", "img");
      marker.setAttribute("aria-label", marker.title);

      const markerImage = document.createElement("img");
      markerImage.src = image;
      markerImage.alt = "";
      marker.append(markerImage);
      els.leaderHomeMarkerLayer.append(marker);
    });
  }

  function leaderHomeMarkerPosition(area) {
    const fallback = { x: area.x, y: area.y };
    const territories = areaHitMap?.territories;
    if (!territories) return fallback;

    const territoryIndex = territories.ids.indexOf(area.id);
    if (territoryIndex < 0) return fallback;

    let best = null;
    for (let offsetY = -8; offsetY <= 8; offsetY += 0.5) {
      for (let offsetX = -10; offsetX <= 10; offsetX += 0.5) {
        const mapDistance = Math.hypot(offsetX, offsetY * (areaHitMap.height / areaHitMap.width));
        if (mapDistance < 5.5 || mapDistance > 8.5) continue;

        const candidate = { x: area.x + offsetX, y: area.y + offsetY };
        if (!leaderHomeMarkerFitsTerritory(candidate, territoryIndex)) continue;

        const directionPenalty = (offsetY <= 0 ? 0.3 : 0) + (offsetX <= 0 ? 0.18 : 0);
        const score = Math.abs(mapDistance - 6.5) + directionPenalty;
        if (!best || score < best.score) best = { ...candidate, score };
      }
    }

    return best || fallback;
  }

  function leaderHomeMarkerFitsTerritory(point, territoryIndex) {
    const halfWidth = 2.35;
    const halfHeight = 1.9;
    const samples = [-1, -0.5, 0, 0.5, 1];

    return samples.every((xFactor) => samples.every((yFactor) => {
      const x = Math.round(((point.x + (halfWidth * xFactor)) / 100) * (areaHitMap.width - 1));
      const y = Math.round(((point.y + (halfHeight * yFactor)) / 100) * (areaHitMap.height - 1));
      const index = hitIndex(x, y);
      return index !== null && areaHitMap.territories.labels[index] === territoryIndex;
    }));
  }

  function trackMarkerFan(index, count) {
    const fans = {
      2: [[-10, -3, -2], [10, 3, 2]],
      3: [[-14, 3, -3], [0, -4, 0], [14, 3, 3]],
      4: [[-18, -4, -4], [-6, 4, -1.5], [6, -4, 1.5], [18, 4, 4]]
    };
    const expandedFans = {
      2: [[-72, -35, -4], [72, 35, 4]],
      3: [[-85, -45, -6], [0, 65, 0], [85, -45, 6]],
      4: [[-75, -75, -6], [75, -75, 6], [-75, 75, 4], [75, 75, -4]]
    };
    const [x, y, rotation] = fans[count]?.[index] || [0, 0, 0];
    const [expandedX, expandedY, expandedRotation] = expandedFans[count]?.[index] || [0, 0, 0];
    return { x, y, rotation, expandedX, expandedY, expandedRotation };
  }

  function controlledTribes() {
    return new Set(Object.values(state.units).filter((unit) => {
      const area = areas[unit.location];
      return unit.owner === "roman" && unit.type !== "roman" && area?.region && area.region !== "roman" && !area.sea;
    }).map((unit) => unit.location)).size;
  }

  function recordTrackPosition(value) {
    const tracked = Math.max(0, Math.min(Number(value) || 0, 19));
    return {
      x: tracked >= 10 ? 7.81 : 4.54,
      y: 72.19 - ((tracked % 10) * 2.7)
    };
  }

  function turnTrackPosition(turn) {
    const tracked = Math.max(0, Math.min(Number(turn) || 0, gameData.years.length - 1));
    return { x: 73.19 + (tracked * 3.11), y: 92.78 };
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

    const territoryIndex = areaHitMap.territories?.labels[index];
    const territoryAreaId = areaHitMap.territories?.ids[territoryIndex];
    if (territoryAreaId) return territoryAreaId;

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
    const componentSizes = [];
    const queue = new Int32Array(labels.length);
    for (let index = 0; index < labels.length; index += 1) {
      if (labels[index] !== -2) continue;
      componentSizes[componentId] = floodFillHitComponent(index, componentId, labels, queue, canvas.width, canvas.height);
      componentId += 1;
    }

    const componentSeeds = new Map();
    const areaSeeds = [];
    Object.values(areas).filter((area) => !area.sea).forEach((area) => {
      const seeds = [[area.x, area.y], ...(territorySupplementalSeeds[area.id] || [])];
      seeds.forEach(([seedX, seedY]) => {
        const x = Math.round((seedX / 100) * (canvas.width - 1));
        const y = Math.round((seedY / 100) * (canvas.height - 1));
        const index = nearestLabeledHitPixel(labels, componentSizes, canvas.width, canvas.height, x, y);
        if (index === null) return;

        const seedComponent = labels[index];
        if (seedComponent < 0) return;
        areaSeeds.push({ areaId: area.id, index });
        if (!componentSeeds.has(seedComponent)) componentSeeds.set(seedComponent, []);
        componentSeeds.get(seedComponent).push({ areaId: area.id, x: index % canvas.width, y: Math.floor(index / canvas.width) });
      });
    });

    const territories = buildHitTerritories(labels, canvas.width, areaSeeds);
    const borderPoints = findSharedBorderPoints(labels, territories, canvas.width, canvas.height);
    areaHitMap = { width: canvas.width, height: canvas.height, labels, componentSeeds, territories, borderPoints };
    areaOverlayCache.clear();
    if (state) {
      renderAreas();
      renderMovementArrows();
      renderLeaderHomeMarkers();
    }
  }

  function buildHitTerritories(labels, width, areaSeeds) {
    const territoryIds = [...new Set(areaSeeds.map((seed) => seed.areaId))];
    const territoryIndexes = new Map(territoryIds.map((areaId, index) => [areaId, index]));
    const territoryLabels = new Int16Array(labels.length);
    territoryLabels.fill(-1);
    const queue = new Int32Array(labels.length);
    let head = 0;
    let tail = 0;

    areaSeeds.forEach((seed) => {
      const territoryIndex = territoryIndexes.get(seed.areaId);
      territoryLabels[seed.index] = territoryIndex;
      queue[tail] = seed.index;
      tail += 1;
    });

    while (head < tail) {
      const index = queue[head];
      head += 1;
      const territoryIndex = territoryLabels[index];
      const x = index % width;
      if (x > 0) tail = enqueueTerritory(index - 1, territoryIndex, labels, territoryLabels, queue, tail);
      if (x < width - 1) tail = enqueueTerritory(index + 1, territoryIndex, labels, territoryLabels, queue, tail);
      if (index >= width) tail = enqueueTerritory(index - width, territoryIndex, labels, territoryLabels, queue, tail);
      if (index < labels.length - width) tail = enqueueTerritory(index + width, territoryIndex, labels, territoryLabels, queue, tail);
    }

    return { ids: territoryIds, labels: territoryLabels };
  }

  function enqueueTerritory(index, territoryIndex, labels, territoryLabels, queue, tail) {
    if (labels[index] < 0 || territoryLabels[index] >= 0) return tail;
    territoryLabels[index] = territoryIndex;
    queue[tail] = index;
    return tail + 1;
  }

  function findSharedBorderPoints(labels, territories, width, height) {
    const connectedAreas = new Set();
    Object.values(areas).forEach((area) => {
      (area.links || []).forEach((linkedAreaId) => {
        connectedAreas.add(areaPairKey(area.id, linkedAreaId));
      });
    });

    const totals = new Map();
    for (let y = 4; y < height - 4; y += 1) {
      for (let x = 4; x < width - 4; x += 1) {
        if (labels[(y * width) + x] !== -1) continue;
        const touching = nearbyHitTerritories(territories.labels, width, x, y);
        for (let left = 0; left < touching.length; left += 1) {
          for (let right = left + 1; right < touching.length; right += 1) {
            const pairKey = areaPairKey(territories.ids[touching[left]], territories.ids[touching[right]]);
            if (!connectedAreas.has(pairKey)) continue;
            const total = totals.get(pairKey) || { x: 0, y: 0, count: 0 };
            total.x += x;
            total.y += y;
            total.count += 1;
            totals.set(pairKey, total);
          }
        }
      }
    }

    const points = new Map();
    totals.forEach((total, pairKey) => {
      if (!total.count) return;
      points.set(pairKey, {
        x: ((total.x / total.count) / (width - 1)) * 100,
        y: ((total.y / total.count) / (height - 1)) * 100
      });
    });
    return points;
  }

  function nearbyHitTerritories(territoryLabels, width, x, y) {
    const territoryIndexes = new Set();
    for (let radius = 1; radius <= 4; radius += 1) {
      [
        [radius, 0], [-radius, 0], [0, radius], [0, -radius],
        [radius, radius], [radius, -radius], [-radius, radius], [-radius, -radius]
      ].forEach(([dx, dy]) => {
        const territoryIndex = territoryLabels[((y + dy) * width) + x + dx];
        if (territoryIndex >= 0) territoryIndexes.add(territoryIndex);
      });
    }
    return [...territoryIndexes];
  }

  function isBorderPixel(red, green, blue) {
    const average = (red + green + blue) / 3;
    const chroma = Math.max(red, green, blue) - Math.min(red, green, blue);
    const riverBoundary = blue > green && green > red && blue - red > 40 && average < 160;
    return riverBoundary || average < 100 || (average < 175 && chroma < 24);
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

    return tail;
  }

  function enqueueHitNeighbor(index, componentId, labels, queue, tail) {
    if (labels[index] !== -2) return tail;
    labels[index] = componentId;
    queue[tail] = index;
    return tail + 1;
  }

  function nearestLabeledHitPixel(labels, componentSizes, width, height, x, y) {
    const direct = y * width + x;
    if (labels[direct] >= 0 && componentSizes[labels[direct]] >= minimumHitComponentSize) return direct;

    for (let radius = 1; radius <= 24; radius += 1) {
      for (let dy = -radius; dy <= radius; dy += 1) {
        for (let dx = -radius; dx <= radius; dx += 1) {
          if (Math.abs(dx) !== radius && Math.abs(dy) !== radius) continue;
          const nextX = x + dx;
          const nextY = y + dy;
          if (nextX < 0 || nextY < 0 || nextX >= width || nextY >= height) continue;
          const index = nextY * width + nextX;
          if (labels[index] >= 0 && componentSizes[labels[index]] >= minimumHitComponentSize) return index;
        }
      }
    }
    return null;
  }

  function activeSplayArea() {
    if (mainForceTargeting()) return mainForceSelection.areaId;
    if (voluntaryRetreatTargeting()) return state.battle?.area;
    if (revoltTargeting()) return revoltTargetSelection.focusedArea;
    if (battleMapMode()) return state.battle.area;
    if (!state.movement) return null;

    const draggingUnit = dragState && state.units[dragState.unitId];
    if (draggingUnit) return draggingUnit.location;

    const selectedUnit = state.selectedUnit && state.units[state.selectedUnit];
    if (selectedUnit?.owner === state.active) return selectedUnit.location;

    const activatedAreas = state.movement.areas || [];
    return activatedAreas[activatedAreas.length - 1] || null;
  }

  function movementArrival(unit) {
    if (!state.movement || retreatMovement() || battleMapMode()) return null;
    const moved = state.movement.units?.[unit.id];
    return Number(moved?.steps) > 0 ? moved : null;
  }

  function compactGroupMetrics(count) {
    const columns = Math.min(4, count);
    const rows = Math.ceil(count / columns);
    return {
      columns,
      rows,
      width: Math.max(58, columns * 16 + 38),
      height: Math.max(58, rows * 20 + 38)
    };
  }

  function compactGroupOffsets(units, centerX = 0, centerY = 0) {
    const metrics = compactGroupMetrics(units.length);
    return new Map(units.map((unit, index) => {
      const row = Math.floor(index / metrics.columns);
      const column = index % metrics.columns;
      const columnsInRow = Math.min(metrics.columns, units.length - row * metrics.columns);
      return [unit.id, {
        x: centerX + ((column - (columnsInRow - 1) / 2) * 16),
        y: centerY + ((row - (metrics.rows - 1) / 2) * 20)
      }];
    }));
  }

  function arrivalLaneDirection(area, arrivals) {
    const origins = arrivals
      .map((unit) => {
        const moved = movementArrival(unit);
        const originId = moved?.entry || moved?.path?.at(-1)?.from || moved?.origin;
        return areas[originId];
      })
      .filter(Boolean);
    if (!origins.length) return { axis: "horizontal", before: false };

    const originX = origins.reduce((sum, origin) => sum + origin.x, 0) / origins.length;
    const originY = origins.reduce((sum, origin) => sum + origin.y, 0) / origins.length;
    const deltaX = originX - area.x;
    const deltaY = originY - area.y;
    return Math.abs(deltaX) >= Math.abs(deltaY)
      ? { axis: "horizontal", before: deltaX < 0 }
      : { axis: "vertical", before: deltaY < 0 };
  }

  function renderPieces() {
    els.pieceLayer.innerHTML = "";
    splayedPieceStack = null;
    if ((piecesHidden && !revoltTargeting() && !voluntaryRetreatTargeting() && !mainForceTargeting()) || targetingPoliticalAction()) return;

    const byArea = {};
    Object.values(state.units).forEach((unit) => {
      if (!areas[unit.location]) return;
      if (mainForceOriginIds().includes(unit.location)) return;
      if (mainForceTargeting() && unit.location === mainForceSelection.areaId && !mainForceEligible(unit)) return;
      byArea[unit.location] ||= [];
      byArea[unit.location].push(unit);
    });

    Object.entries(byArea).forEach(([areaId, units]) => {
      const area = areas[areaId];
      const residents = units.filter((unit) => !movementArrival(unit));
      const arrivals = units.filter((unit) => movementArrival(unit));
      const displayUnits = [...residents, ...arrivals];
      const hasArrivalLane = residents.length > 0 && arrivals.length > 0;
      const residentMetrics = compactGroupMetrics(residents.length || displayUnits.length);
      const arrivalMetrics = compactGroupMetrics(arrivals.length || displayUnits.length);
      const laneGap = 4;
      const laneDirection = arrivalLaneDirection(area, arrivals);
      const horizontalLanes = hasArrivalLane && laneDirection.axis === "horizontal";
      const verticalLanes = hasArrivalLane && laneDirection.axis === "vertical";
      const compactWidth = horizontalLanes
        ? residentMetrics.width + laneGap + arrivalMetrics.width
        : Math.max(residentMetrics.width, arrivalMetrics.width);
      const compactHeight = verticalLanes
        ? residentMetrics.height + laneGap + arrivalMetrics.height
        : Math.max(residentMetrics.height, arrivalMetrics.height);
      const firstHorizontalCenter = (-compactWidth / 2) + ((laneDirection.before ? arrivalMetrics : residentMetrics).width / 2);
      const secondHorizontalCenter = (compactWidth / 2) - ((laneDirection.before ? residentMetrics : arrivalMetrics).width / 2);
      const firstVerticalCenter = (-compactHeight / 2) + ((laneDirection.before ? arrivalMetrics : residentMetrics).height / 2);
      const secondVerticalCenter = (compactHeight / 2) - ((laneDirection.before ? residentMetrics : arrivalMetrics).height / 2);
      const residentCenterX = horizontalLanes ? (laneDirection.before ? secondHorizontalCenter : firstHorizontalCenter) : 0;
      const arrivalCenterX = horizontalLanes ? (laneDirection.before ? firstHorizontalCenter : secondHorizontalCenter) : 0;
      const residentCenterY = verticalLanes ? (laneDirection.before ? secondVerticalCenter : firstVerticalCenter) : 0;
      const arrivalCenterY = verticalLanes ? (laneDirection.before ? firstVerticalCenter : secondVerticalCenter) : 0;
      const compactOffsets = hasArrivalLane
        ? new Map([
            ...compactGroupOffsets(residents, residentCenterX, residentCenterY),
            ...compactGroupOffsets(arrivals, arrivalCenterX, arrivalCenterY)
          ])
        : compactGroupOffsets(displayUnits);
      const canSplay = displayUnits.length > 1 && (
        displayUnits.every(unitFaceVisibleToActivePlayer) ||
        (revoltTargeting() && displayUnits.some(revoltTargetEligible)) ||
        (mainForceTargeting() && displayUnits.some(mainForceEligible))
      );
      const columns = Math.min(4, displayUnits.length);
      const rows = Math.ceil(displayUnits.length / columns);
      const stack = document.createElement("div");
      const mainForceBattleStack = mainForceSelection?.areaId === areaId;
      stack.className = `piece-stack${displayUnits.length > 1 ? " has-multiple" : ""}${canSplay ? " can-splay" : ""}${arrivals.length ? " has-movement-arrivals" : ""}${mainForceBattleStack ? " is-main-force-battle-stack" : ""}${displayUnits.some((unit) => state.selectedUnit === unit.id) ? " has-selected" : ""}`;
      stack.style.left = `${area.x}%`;
      stack.style.top = `${area.y}%`;
      stack.style.setProperty("--compact-width", `${compactWidth}px`);
      stack.style.setProperty("--compact-height", `${compactHeight}px`);
      stack.style.setProperty("--splay-width", `${Math.max(78, columns * 68 + 44)}px`);
      stack.style.setProperty("--splay-height", `${Math.max(78, rows * 68 + 44)}px`);
      const keepStackSplayed = () => {
        const restrictedArea = activeSplayArea();
        if (restrictedArea && restrictedArea !== areaId) return;
        if (splayedPieceStack && splayedPieceStack !== stack) {
          splayedPieceStack.classList.remove("is-splayed");
        }
        if (!canSplay) {
          splayedPieceStack = null;
          return;
        }
        stack.classList.add("is-splayed");
        splayedPieceStack = stack;
      };
      stack.addEventListener("pointerenter", keepStackSplayed);
      stack.addEventListener("focusin", keepStackSplayed);
      if (revoltTargetSelection?.focusedArea === areaId && canSplay) {
        stack.classList.add("is-splayed");
        splayedPieceStack = stack;
      }
      if (mainForceSelection?.areaId === areaId && canSplay) {
        stack.classList.add("is-splayed");
        splayedPieceStack = stack;
      }
      stack.addEventListener("click", (event) => {
        if (event.target !== stack) return;
        event.stopPropagation();
        if (winterQuartersActive()) return;
        moveSelectedTo(areaId);
      });

      displayUnits.forEach((unit, index) => {
        const row = Math.floor(index / columns);
        const column = index % columns;
        const columnsInRow = Math.min(columns, displayUnits.length - row * columns);
        const compactOffset = compactOffsets.get(unit.id);
        const compactX = compactOffset.x;
        const compactY = compactOffset.y;
        const splayX = (column - (columnsInRow - 1) / 2) * 68;
        const splayY = (row - (rows - 1) / 2) * 68;
        const piece = document.createElement("button");
        piece.className = `piece owner-${unit.owner}`;
        const arrival = movementArrival(unit);
        const winterEligible = winterQuartersEligible(unit.id);
        const revoltEligible = revoltTargetEligible(unit);
        const mainForceTarget = mainForceEligible(unit);
        const faceVisible = winterEligible || revoltEligible || mainForceTarget || unitFaceVisibleToActivePlayer(unit);
        piece.classList.toggle("is-selected", state.selectedUnit === unit.id);
        piece.classList.toggle("is-revolt-target", revoltEligible);
        piece.classList.toggle("is-revolt-ineligible", revoltTargeting() && !revoltEligible);
        piece.classList.toggle("is-main-force-target", mainForceTarget);
        piece.classList.toggle("is-main-force-ineligible", mainForceTargeting() && !mainForceTarget);
        piece.classList.toggle("is-winter-eligible", winterEligible);
        piece.classList.toggle("is-wintering", winterEligible && winteringUnitIds().includes(unit.id));
        piece.classList.toggle("is-winter-ineligible", winterQuartersActive() && !winterEligible);
        piece.classList.toggle("is-movement-arrival", Boolean(arrival));
        piece.classList.toggle("is-hidden", !faceVisible);
        if (!faceVisible) {
          piece.classList.add(`hidden-region-${hiddenBlockRegion(unit)}`);
          piece.classList.add(unit.owner === "neutral" ? "is-hidden-neutral" : "is-hidden-enemy");
        }
        piece.style.setProperty("--compact-x", `${compactX}px`);
        piece.style.setProperty("--compact-y", `${compactY}px`);
        piece.style.setProperty("--splay-x", `${splayX}px`);
        piece.style.setProperty("--splay-y", `${splayY}px`);
        piece.style.zIndex = index + 1;
        const hiddenLabel = unit.owner === "neutral" ? "Neutral block" : "Enemy block";
        if (winterEligible) {
          piece.title = winteringUnitIds().includes(unit.id)
            ? `${unit.name} will winter in ${areaName(unit.location)}. Click to send it to Transalpine Gaul.`
            : `${unit.name} will return to Transalpine Gaul. Click to winter it in ${areaName(unit.location)}.`;
          piece.setAttribute("aria-pressed", winteringUnitIds().includes(unit.id) ? "true" : "false");
        } else if (revoltEligible) {
          piece.title = `${unit.name}, currently in ${areaName(unit.location)}; returns home to ${areaName(unit.home)}. Click to choose.`;
        } else if (mainForceTarget) {
          piece.title = `Choose ${unit.name}'s group from ${areaName(movementEntry(unit, mainForceSelection.areaId))} as the main force.`;
        } else {
          const movementNote = arrival
            ? ` Moved here this action${movementUsedForceMarch(arrival) ? " by forced march" : ""}.`
            : "";
          piece.title = faceVisible ? `${unit.name}, strength ${currentStrength(unit)}.${movementNote} Double-click for history.` : hiddenLabel;
        }
        piece.innerHTML = unitCounterMarkup(unit, {
          faceVisible,
          showStrength: !revoltEligible || unitFaceVisibleToActivePlayer(unit)
        });
        piece.addEventListener("click", (event) => {
          event.stopPropagation();
          if (suppressNextPieceClick) {
            suppressNextPieceClick = false;
            return;
          }
          if (piece.dataset.pointerGesture === "true") {
            delete piece.dataset.pointerGesture;
            return;
          }
          selectUnit(unit.id);
        });
        if (faceVisible && !winterQuartersActive() && !revoltTargeting() && !voluntaryRetreatTargeting() && !mainForceTargeting()) {
          piece.addEventListener("dblclick", (event) => {
            event.preventDefault();
            event.stopPropagation();
            showUnitHistory(unit.id);
          });
        }
        if (!winterQuartersActive() && !revoltTargeting() && !voluntaryRetreatTargeting() && !mainForceTargeting()) {
          piece.addEventListener("pointerdown", (event) => beginPieceDrag(event, unit.id));
        }
        stack.append(piece);
      });
      els.pieceLayer.append(stack);
    });
  }

  function renderNeutralActivationCards() {
    els.neutralActivationLayer.innerHTML = "";
    els.neutralActivationLayer.hidden = false;
    els.neutralActivationLayer.classList.toggle(
      "is-passive",
      battleMapMode() || winterQuartersActive() || revoltTargeting() || voluntaryRetreatTargeting() || mainForceTargeting()
    );

    const slots = [
      { player: "barbarian", label: "German player neutral tribe activation", cards: state.neutralActivationCards.barbarian || [] },
      { player: "roman", label: "Roman player neutral tribe activation", cards: state.neutralActivationCards.roman || [] }
    ];

    slots.forEach((slot) => {
      const container = document.createElement("div");
      container.className = `neutral-activation-slot neutral-activation-slot-${slot.player}`;
      container.setAttribute("aria-label", slot.label);

      const cards = slot.cards.slice(-2);
      if (cards.length === 0) {
        container.innerHTML = `<span>${slot.player === "roman" ? "Roman" : "German"} NTA</span>`;
      } else {
        container.title = cards.map((card) => `${card.title}, AP ${card.ap}`).join("\n");
        cards.forEach((card, index) => {
          const marker = document.createElement("div");
          marker.className = "neutral-activation-card";
          marker.style.setProperty("--stack-index", index);
          marker.style.zIndex = index + 1;
          const image = cardImage(card);
          if (image) {
            marker.innerHTML = `<img src="${image}" alt="${card.title} card">`;
          } else {
            marker.innerHTML = `<strong>${card.title}</strong><small>AP ${card.ap}</small>`;
          }
          container.append(marker);
        });
      }

      els.neutralActivationLayer.append(container);
    });
  }

  function cardImage(card) {
    return gameData.cards.find((candidate) => candidate.id === card.id)?.image;
  }

  function beginPieceDrag(event, unitId) {
    if (event.button !== 0) return;
    if (winterQuartersActive()) return;
    const unit = state.units[unitId];
    if (battleMapMode()) {
      if (!canBattleMapUnit(unit)) return;
    } else {
      if (unit.owner !== state.active) return;
      if (state.battle) return;
    }

    event.preventDefault();
    event.stopPropagation();
    event.currentTarget.setPointerCapture(event.pointerId);
    event.currentTarget.dataset.pointerGesture = "true";
    markUnitSelected(unitId);
    event.currentTarget.closest(".piece-stack")?.classList.add("has-selected");
    event.currentTarget.parentElement?.querySelectorAll(".piece").forEach((piece) => {
      piece.classList.toggle("is-selected", piece === event.currentTarget);
    });
    renderAreas();
    if (!battleMapMode() && !state.movement) {
      event.currentTarget.releasePointerCapture(event.pointerId);
      return;
    }

    dragState = {
      unitId,
      pointerId: event.pointerId,
      startX: event.clientX,
      startY: event.clientY,
      dragged: false,
      ghost: null,
      activation: null
    };
    event.currentTarget.addEventListener("pointermove", updatePieceDrag);
    event.currentTarget.addEventListener("pointerup", endPieceDrag);
    event.currentTarget.addEventListener("pointercancel", cancelPieceDrag);
    dragState.activation = !battleMapMode() && !movementAreaActivated(movementOrigin(unit))
      ? activateMovementArea(movementOrigin(unit))
      : Promise.resolve(true);
  }

  function updatePieceDrag(event) {
    if (!dragState || event.pointerId !== dragState.pointerId) return;
    const distance = Math.hypot(event.clientX - dragState.startX, event.clientY - dragState.startY);
    if (!dragState.dragged && distance > 4) {
      dragState.dragged = true;
      dragState.ghost = createDragGhost(event.currentTarget, event.clientX, event.clientY);
      event.currentTarget.classList.add("is-dragging");
    }
    moveDragGhost(event.clientX, event.clientY);
    if (!dragState.dragged) return;

    const areaId = areaFromClientPoint(event.clientX, event.clientY);
    if (state.dragArea !== areaId) {
      state.dragArea = areaId;
      renderAreas();
    }
  }

  async function endPieceDrag(event) {
    if (!dragState || event.pointerId !== dragState.pointerId) return;
    const activeDrag = dragState;
    const piece = event.currentTarget;
    const target = state.dragArea || areaFromClientPoint(event.clientX, event.clientY);
    const dragged = dragState.dragged;
    const unitId = dragState.unitId;
    if (dragged) suppressNextPieceClick = true;
    const activated = await activeDrag.activation;
    if (dragState !== activeDrag) return;
    if (!activated) {
      cleanupPieceDrag(piece);
      dragState = null;
      render();
      return;
    }
    if (dragged && target) {
      cleanupPieceDrag(piece, { keepGhost: true });
      try {
        if (battleMapMode()) await battleMapUnitTo(unitId, target);
        else await moveUnitTo(unitId, target);
      } finally {
        cleanupPieceDrag(piece);
        dragState = null;
      }
    } else {
      cleanupPieceDrag(piece);
      dragState = null;
      renderAreas();
    }
  }

  function cancelPieceDrag(event) {
    if (!dragState || event.pointerId !== dragState.pointerId) return;
    cleanupPieceDrag(event.currentTarget);
    dragState = null;
    renderAreas();
  }

  function cleanupPieceDrag(piece, { keepGhost = false } = {}) {
    if (dragState && piece.hasPointerCapture?.(dragState.pointerId)) piece.releasePointerCapture(dragState.pointerId);
    if (!keepGhost) dragState?.ghost?.remove();
    if (!keepGhost) piece.classList.remove("is-dragging");
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
    const hotseat = state.mode === "hotseat";
    els.handTray.classList.toggle("is-hotseat", hotseat);
    [["roman", els.romanHand], ["barbarian", els.barbarianHand]].forEach(([player, container]) => {
      const activeHand = hotseat ? player === state.active : player === "roman";
      container.closest(".hand-zone").hidden = !activeHand;
      if (activeHand) renderHand(player, container);
      else container.replaceChildren();
    });
    renderDiscardPile();
    renderCardZoom();
  }

  function renderDiscardPile() {
    if (!els.discardZone || !els.discardPile || !els.discardCount) return;

    const cards = state.discard || [];
    els.discardZone.hidden = false;
    els.discardCount.textContent = String(cards.length);
    els.discardPile.replaceChildren();
    els.discardPile.setAttribute("aria-label", cards.length === 1 ? "Discard pile, 1 card" : `Discard pile, ${cards.length} cards`);

    if (cards.length === 0) {
      const empty = document.createElement("div");
      empty.className = "discard-pile-empty";
      empty.textContent = "No cards discarded";
      els.discardPile.append(empty);
      return;
    }

    const lastIndex = cards.length - 1;
    const spread = lastIndex > 0 ? Math.min(82, Math.max(46, 620 / lastIndex)) : 0;
    cards.forEach((card, index) => {
      const discarded = document.createElement("div");
      const image = cardImage(card);
      const depth = lastIndex - index;
      const stackOffset = Math.min(depth, 5) * 3;
      discarded.className = "discard-card";
      discarded.setAttribute("role", "img");
      discarded.setAttribute("aria-label", `${card.title}, ${card.ap} action point${card.ap === 1 ? "" : "s"}`);
      discarded.style.right = `${stackOffset}px`;
      discarded.style.bottom = `${Math.min(depth, 5) * 2}px`;
      discarded.style.zIndex = `${index + 1}`;
      discarded.style.setProperty("--discard-expanded-x", `${-depth * spread}px`);
      discarded.style.setProperty("--discard-expanded-rotation", `${(index - lastIndex / 2) * 1.25}deg`);
      discarded.innerHTML = image
        ? `<img src="${image}" alt="${card.title} card">`
        : `<span class="card-title-fallback"><strong>${card.title}</strong><small>${card.ap} ${card.type}</small></span>`;
      els.discardPile.append(discarded);
    });
  }

  function renderHand(player, container) {
    container.innerHTML = "";
    const cards = state.hands[player];
    cards.forEach((card, index) => {
      const button = document.createElement("button");
      const currentPlayer = player === state.active;
      const committed = state.committed[player]?.id === card.id;
      const hidden = state.mode === "hotseat" && !currentPlayer;
      const hotseatLocked = state.mode === "hotseat" && (state.revealed ? !committed : committed);
      const tilt = cards.length > 1 ? (index - (cards.length - 1) / 2) * 4 : 0;
      const lift = Math.abs(index - (cards.length - 1) / 2) * 2;
      button.className = `card${hidden ? " is-hidden" : ""}`;
      button.disabled = hidden || Boolean(state.movement) || Boolean(state.battle) || hotseatLocked;
      button.classList.toggle("is-active", currentPlayer && state.selectedCard?.id === card.id);
      button.classList.toggle("is-zoomed", zoomedCardId === card.id);
      button.style.setProperty("--tilt", `${tilt}deg`);
      button.style.setProperty("--lift", `${lift}px`);
      if (hidden) {
        button.innerHTML = "<span>Hidden card</span>";
      } else if (committed && !state.revealed) {
        button.innerHTML = "<strong>Committed</strong><small>Face down</small>";
      } else {
        const image = cardImage(card);
        button.innerHTML = image ? `<img src="${image}" alt="${card.title} card">` : `<span class="card-title-fallback"><strong>${card.title}</strong><small>${card.ap} ${card.type}</small></span>`;
      }
      button.addEventListener("click", () => {
        if (player !== state.active) return;
        state.selectedCard = card;
        zoomedCardId = zoomedCardId === card.id ? null : card.id;
        render();
      });
      container.append(button);
    });
  }

  function zoomedCard() {
    if (!zoomedCardId) return null;

    return ["roman", "barbarian"].flatMap((player) => state.hands[player] || []).find((card) => card.id === zoomedCardId) || null;
  }

  function renderCardZoom() {
    if (!els.cardZoom) return;

    const card = zoomedCard();
    if (!card) {
      zoomedCardId = null;
      els.cardZoom.hidden = true;
      els.cardZoom.innerHTML = "";
      return;
    }

    const image = cardImage(card);
    const actions = cardZoomActions(card);
    els.cardZoom.hidden = false;
    els.cardZoom.innerHTML = `
      <div class="card-zoom-content">
        <button type="button" class="card-zoom-card" aria-label="Close ${card.title} preview">
          ${image ? `<img src="${image}" alt="${card.title} card">` : `<span class="card-title-fallback"><strong>${card.title}</strong><small>${card.ap} ${card.type}</small></span>`}
        </button>
        <section class="card-zoom-actions" aria-label="Actions for ${card.title}">
          <span>Play this card</span>
          <strong>${card.title}</strong>
          <small>AP ${card.ap} · Choose an action</small>
          <div class="card-zoom-action-list">
            ${actions.map((action) => `
              <button type="button" data-card-zoom-action="${action.id}"${action.disabled ? " disabled aria-disabled=\"true\"" : ""}>
                <strong>${action.label}</strong>
                <span>${action.detail}</span>
              </button>
            `).join("")}
          </div>
        </section>
      </div>
    `;
    els.cardZoom.querySelector(".card-zoom-card").addEventListener("click", () => {
      zoomedCardId = null;
      render();
    });
    els.cardZoom.querySelectorAll("[data-card-zoom-action]").forEach((button) => {
      button.addEventListener("click", () => playCardZoomAction(button.dataset.cardZoomAction));
    });
  }

  function cardZoomActions(card) {
    if (state.mode === "hotseat" && !state.revealed) {
      return [{ id: "commit", label: "Commit Face Down", detail: `Commit ${card.title}, then pass to the other player` }];
    }

    const supplyDetail = state.active === "roman"
      ? `Gain ${card.ap * 2} Roman Supply`
      : `Reduce Roman Supply by ${card.ap}`;
    const actions = [];
    if (!(state.active === "roman" && card.title === "Baggage Train")) {
      actions.push({ id: "supply", label: "Supply", detail: supplyDetail });
    }
    if (card.area) {
      const activationLimit = neutralActivationLimit(state.active);
      const activationsUsed = neutralActivationsUsed(state.active);
      const activationLimitReached = activationsUsed >= activationLimit;
      const targetBlocked = state.active === "roman" && romanSpecialTargetBlockReason(card.area, "neutral activation");
      actions.push({
        id: "activate",
        label: "Neutral Tribe",
        detail: targetBlocked || (activationLimitReached
          ? `Yearly limit reached (${activationsUsed} of ${activationLimit} used)`
          : `Activate eligible tribes in ${areaName(card.area)} · ${activationsUsed} of ${activationLimit} used`),
        disabled: activationLimitReached || Boolean(targetBlocked)
      });
    }
    const cardAreaPoliticalBlocked = state.active === "roman" && romanSpecialTargetBlockReason(card.area, "political action");
    actions.push(
      {
        id: "political",
        label: "Political",
        detail: cardAreaPoliticalBlocked
          ? `Britannia unavailable · other targets may be selected using AP ${card.ap}`
          : `Attempt control using AP ${card.ap}`
      },
      { id: "movement", label: "Movement", detail: `Activate up to ${card.ap} group${card.ap === 1 ? "" : "s"}` }
    );
    if (card.type === "event") {
      actions.push({ id: "event", label: "Event", detail: `Resolve ${card.title}` });
    }
    return actions;
  }

  function neutralActivationLimit(player) {
    return player === "roman" ? 1 : 2;
  }

  function neutralActivationsUsed(player) {
    return state.neutralActivationCards?.[player]?.length || 0;
  }

  function romanLegionOnNorthernCoast() {
    return Object.values(state.units).some((unit) =>
      unit.type === "roman" &&
      unit.owner === "roman" &&
      currentStrength(unit) > 0 &&
      areas[unit.location]?.links?.includes("oceanus_britannicus")
    );
  }

  function romanSpecialTargetBlockReason(areaId, action) {
    const area = areas[areaId];
    if (!area) return null;
    if (area.id === "germania") return `Romans may not use ${action} against Germania.`;
    if (area.region === "britannia" && !romanLegionOnNorthernCoast()) {
      return `Romans need at least one legion on the northern coast to use ${action} in Britannia.`;
    }
    return null;
  }

  async function playCardZoomAction(action) {
    if (action === "commit") {
      await commitCard();
      return;
    }
    zoomedCardId = null;
    handHidden = true;
    render();
    await playAction(action);
  }

  function toggleHand() {
    if (hotseatHandLocked()) return;
    handHidden = !handHidden;
    if (handHidden) zoomedCardId = null;
    renderHandToggle();
    renderCardZoom();
  }

  function renderHandToggle() {
    if (!els.handTray || !els.toggleHand) return;
    const playerHand = state?.mode === "hotseat" ? `${playerName(state.active)} Hand` : "Hand";
    const locked = hotseatHandLocked();
    els.handTray.classList.toggle("is-hidden", handHidden);
    els.toggleHand.textContent = locked ? "Cards Committed" : `${handHidden ? "Show" : "Hide"} ${playerHand}`;
    els.toggleHand.disabled = locked;
    els.toggleHand.setAttribute("aria-expanded", handHidden ? "false" : "true");
    els.handTrayTitle.textContent = state?.mode === "hotseat" ? `${playerName(state.active)} Cards` : "Cards";
    els.handTray.setAttribute("aria-label", playerHand);
  }

  function hotseatHandLocked() {
    return Boolean(state?.mode === "hotseat" && !state.revealed && state.committed?.[state.active]);
  }

  function toggleSidePanel() {
    sidePanelCollapsed = !sidePanelCollapsed;
    renderSidePanelToggle();
  }

  function renderSidePanelToggle() {
    if (!els.shell || !els.sidePanel || !els.toggleSidePanel) return;
    els.shell.classList.toggle("is-side-panel-collapsed", sidePanelCollapsed);
    els.sidePanel.classList.toggle("is-collapsed", sidePanelCollapsed);
    els.toggleSidePanel.textContent = sidePanelCollapsed ? "‹" : "›";
    els.toggleSidePanel.setAttribute("aria-expanded", sidePanelCollapsed ? "false" : "true");
    els.toggleSidePanel.setAttribute("aria-label", sidePanelCollapsed ? "Expand information panel" : "Collapse information panel");
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

  function renderBattleBoard() {
    if (!els.battleDialog) return;
    const battle = state.battle;
    if (!battle) {
      resetBotRollReview();
      resetDiceRollAnimation();
      if (els.battleDialog.open) els.battleDialog.close();
      if (els.battleRoundHeader) els.battleRoundHeader.textContent = "";
      if (els.battleDetails) els.battleDetails.replaceChildren();
      state.regroupUnit = null;
      return;
    }
    if (battleTransitionReview) {
      if (els.battleDialog.open) els.battleDialog.close();
      return;
    }
    if (botActionReview?.battlePending) {
      if (els.battleDialog.open) els.battleDialog.close();
      return;
    }
    if (battleMapMode()) {
      if (els.battleDialog.open) els.battleDialog.close();
      return;
    }
    if (voluntaryRetreatTargeting()) {
      if (els.battleDialog.open) els.battleDialog.close();
      return;
    }
    if (!els.battleDialog.open) {
      if (els.resultDialog?.open) els.resultDialog.close();
      els.battleDialog.showModal();
    }

    const activeUnit = battle.activeUnit ? state.units[battle.activeUnit] : null;
    const status = battleStatusText(battle, activeUnit);
    const defenderFortIds = (battle.fort || []).filter((id) => state.units[id]?.location === battle.area);
    const defenseAdvantages = battleDefenseAdvantages(battle, defenderFortIds);
    const actionHistory = battleActionHistory(battle);
    els.battleRoundHeader.textContent = `Round ${battle.round} / ${battle.maxRounds}`;
    els.battleSummary.innerHTML = `
      <div class="battle-heading">
        <div>
          <span class="battle-kicker">Battle for</span>
          <strong>${areaName(battle.area)}</strong>
        </div>
        <div class="battle-defense-summary" aria-label="Defender advantages">
          ${defenseAdvantages.length
            ? defenseAdvantages.map((advantage) => `<span>${advantage}</span>`).join("")
            : "<span class=\"is-inactive\">No defender advantage</span>"}
        </div>
      </div>
      <span class="battle-status">${status}</span>
    `;

    const reserveIds = new Set(battle.round === 1 ? battle.reserves || [] : []);
    const fortIds = new Set(battle.fort || []);
    const rollReviewEliminatedIds = Object.keys(battle.rollReviewEliminations || {});
    const reviewedEliminations = (owner, zone = "field") => rollReviewEliminatedIds.filter((id) => (
      state.units[id]?.owner === owner && battle.rollReviewEliminations[id]?.zone === zone
    ));
    const attackers = [
      ...(battle.attackers || []).filter((id) => !reserveIds.has(id) && !fortIds.has(id) && state.units[id]?.location === battle.area),
      ...reviewedEliminations(battle.attacker, "field")
    ];
    const defenders = [
      ...(battle.defenders || []).filter((id) => !reserveIds.has(id) && !fortIds.has(id) && state.units[id]?.location === battle.area),
      ...reviewedEliminations(battle.defender, "field")
    ];
    const reserves = battle.round === 1
      ? (battle.reserves || []).filter((id) => state.units[id]?.location === battle.area)
      : [];
    const fort = [
      ...(battle.fort || []).filter((id) => state.units[id]?.location === battle.area),
      ...reviewedEliminations(battle.defender, "fort")
    ];
    const attackerReserves = reserves.filter((id) => state.units[id]?.owner === battle.attacker);
    const defenderReserves = reserves.filter((id) => state.units[id]?.owner === battle.defender);
    els.battleZones.innerHTML = [
      battleArmy(battle.attacker, "Attacker", attackers, attackerReserves, [], battle),
      battleArmy(battle.defender, "Defender", defenders, defenderReserves, fort, battle)
    ].join("");
    els.battleDetails.innerHTML = `
      <section class="battle-log-panel" aria-label="Battle log">
        <div class="battle-details-heading">
          <span>Battle Log</span>
          <b>Round ${battle.round}</b>
        </div>
        ${actionHistory || "<span class=\"battle-log-empty\">No battle actions yet.</span>"}
      </section>
    `;
    wireBattleUnitButtons(battle);
    wireBattleActionButtons();
    reviewSolitaireBotRoll(battle);

    els.battleActions.innerHTML = "";
    if (battle.phase === "regroup") {
      const regroup = document.createElement("button");
      regroup.type = "button";
      regroup.textContent = "Regroup";
      regroup.addEventListener("click", startMapRegroup);
      els.battleActions.append(regroup);

      const hold = document.createElement("button");
      hold.type = "button";
      hold.textContent = "Hold Area";
      hold.addEventListener("click", finishRegroup);
      els.battleActions.append(hold);
      return;
    }
    if (battle.phase === "retreat") {
      const retreat = document.createElement("button");
      retreat.type = "button";
      const trapped = forcedRetreatUnits(battle).every((unit) => legalVoluntaryRetreatTargets(battle, unit).length === 0);
      retreat.textContent = trapped ? "Resolve Trapped Units" : "Retreat";
      retreat.addEventListener("click", trapped ? () => battleAction("finish_retreat") : startMapRetreat);
      els.battleActions.append(retreat);
      return;
    }
  }

  function battleStatusText(battle, activeUnit) {
    if (battle.phase === "regroup") return `${playerName(battle.winner)} won. Regroup victorious units or hold the field.`;
    if (battle.phase === "retreat") {
      const retreaters = forcedRetreatUnits(battle);
      if (retreaters.length && retreaters.every((unit) => legalVoluntaryRetreatTargets(battle, unit).length === 0)) {
        return `${playerName(battle.retreating)} is defeated. Its trapped units have no legal retreat and will be eliminated.`;
      }
      return `${playerName(battle.retreating)} is defeated and must retreat.`;
    }
    if (diceAnimationRollingFor(battle, battle.awaitingRollAcknowledgement)) {
      const firingUnit = state.units[battle.awaitingRollAcknowledgement];
      return `${firingUnit?.name || "The unit"} is rolling...`;
    }
    if (battle.pendingHits?.targetIds?.length) {
      const owner = state.units[battle.pendingHits.targetIds[0]]?.owner;
      const remaining = battle.pendingHits.remaining || 1;
      return `${playerName(owner)} player: choose a strongest unit to take the pending hit${remaining === 1 ? "" : ` (${remaining} remaining)`}.`;
    }
    if (battle.awaitingRollAcknowledgement) {
      const firingUnit = state.units[battle.awaitingRollAcknowledgement];
      if (solitaireBotRoll(battle, battle.awaitingRollAcknowledgement)) {
        return `${firingUnit?.name || "The Barbarian unit"}'s fire result is being resolved.`;
      }
      return `Review ${firingUnit?.name || "the unit"}'s fire result, then click OK.`;
    }
    if (activeUnit) return `${activeUnit.name} is acting.`;
    return "Waiting for the next battle action.";
  }

  function battleArmy(player, role, fieldIds, reserveIds, fortIds, battle) {
    const areaFort = areas[battle.area]?.fort;
    const selected = (id) => battle.phase === "regroup" && id === state.regroupUnit;
    const cards = (unitIds, zone) => unitIds.length
      ? [...unitIds]
        .sort((left, right) => Number(right === battle.activeUnit) - Number(left === battle.activeUnit))
        .map((id) => battleUnitCard(id, battle, selected(id), zone)).join("")
      : "<span class=\"empty-zone\">No units</span>";
    const reserveZone = reserveIds.length ? `
      <div class="battle-subzone battle-reserve-zone">
        <div class="battle-subzone-heading">
          <h4>Reserves</h4>
          <span>Enter next round</span>
        </div>
        <div class="battle-unit-list">${cards(reserveIds, "reserve")}</div>
      </div>
    ` : "";
    const fortName = areaFort?.name ? titleCase(areaFort.name) : "Fort";
    const fortZone = areaFort && player === battle.defender ? `
      <div class="battle-subzone battle-fort-zone">
        <div class="battle-subzone-heading">
          <h4>${fortName}</h4>
          <span>Fort ${fortIds.length}/${areaFort.level}</span>
        </div>
        <div class="battle-unit-list">${fortIds.length ? cards(fortIds, "fort") : "<span class=\"empty-zone\">Unoccupied</span>"}</div>
      </div>
    ` : "";
    const rollAnimating = diceAnimationRollingFor(battle, battle.awaitingRollAcknowledgement);
    const liveCount = [...fieldIds, ...reserveIds, ...fortIds].filter((id) => {
      const unit = state.units[id];
      const beforeRollUnit = rollAnimating ? diceRollAnimation?.beforeUnits?.[id] : null;
      return currentStrength(beforeRollUnit ? { ...unit, ...beforeRollUnit } : unit) > 0;
    }).length;

    return `
      <section class="battle-army owner-${player}">
        <header class="battle-army-header">
          <span class="battle-army-standard" aria-hidden="true"></span>
          <div class="battle-army-identity">
            <h3>${playerName(player)}</h3>
            <span>${role}</span>
          </div>
          <strong>${liveCount} unit${liveCount === 1 ? "" : "s"}</strong>
        </header>
        <div class="battle-subzone battle-field-zone">
          <div class="battle-subzone-heading">
            <h4>Battle Line</h4>
            <span>Active</span>
          </div>
          <div class="battle-unit-list">${cards(fieldIds, "field")}</div>
        </div>
        ${reserveZone}
        ${fortZone}
      </section>
    `;
  }

  function battleDefenseAdvantages(battle, fortIds) {
    const advantages = [];
    if (battle.amphibious) {
      advantages.push("Amphibious: Prepared Defense");
    }
    if (battle.area === "helvetii") {
      advantages.push("Alps: Double Defense");
    }

    const areaFort = areas[battle.area]?.fort;
    if (areaFort && fortIds.length) {
      advantages.push(`${titleCase(areaFort.name)}: Improved Initiative + Double Defense`);
    }

    return advantages;
  }

  function titleCase(value) {
    return String(value).replace(/\b\w/g, (character) => character.toUpperCase());
  }

  function canEnterBattleFort(unit, battle) {
    const areaFort = areas[battle.area]?.fort;
    return Boolean(
      areaFort &&
      unit.owner === battle.defender &&
      !(battle.fort || []).includes(unit.id) &&
      (battle.fort || []).length < areaFort.level
    );
  }

  function wireBattleUnitButtons(battle) {
    els.battleZones.querySelectorAll("[data-battle-unit].is-selectable").forEach((card) => {
      const select = () => {
        const unit = state.units[card.dataset.battleUnit];
        if (!unit) return;
        if ((battle.pendingHits?.targetIds || []).includes(unit.id)) {
          battleAction("assign_hit", null, unit.id);
          return;
        }
        if (!["regroup", "retreat"].includes(battle.phase)) return;
        if (battle.phase === "regroup" && (unit.owner !== battle.winner || unit.location !== battle.area || currentStrength(unit) <= 0)) return;
        if (battle.phase === "retreat" && (unit.owner !== battle.retreating || unit.location !== battle.area || currentStrength(unit) <= 0)) return;

        state.regroupUnit = unit.id;
        render();
      };
      card.addEventListener("click", select);
      card.addEventListener("keydown", (event) => {
        if (!["Enter", " "].includes(event.key)) return;
        event.preventDefault();
        select();
      });
    });
  }

  function wireBattleActionButtons() {
    els.battleZones.querySelectorAll("[data-battle-action]").forEach((button) => {
      button.addEventListener("click", async (event) => {
        event.stopPropagation();
        const action = button.dataset.battleAction;
        const unitId = button.dataset.unitId;
        if (action !== "retreat") {
          await battleAction(action, unitId);
          return;
        }

        const unit = state.units[unitId];
        const targets = legalVoluntaryRetreatTargets(state.battle, unit);
        if (!targets.length) {
          log(`${unit.name} has no legal retreat area.`);
          render();
          return;
        }

        startVoluntaryRetreatTargeting(unitId, targets);
      });
    });
  }

  function voluntaryRetreatTargeting() {
    return Boolean(
      voluntaryRetreatSelection &&
      state.battle &&
      state.units[voluntaryRetreatSelection.unitId]?.location === state.battle.area
    );
  }

  function voluntaryRetreatTargetAreaIds() {
    return voluntaryRetreatTargeting() ? voluntaryRetreatSelection.targets : [];
  }

  function startVoluntaryRetreatTargeting(unitId, targets) {
    const unit = state.units[unitId];
    if (!unit || !targets.length) return;

    voluntaryRetreatSelection = { unitId, targets };
    state.selectedUnit = unitId;
    state.selectedArea = state.battle.area;
    piecesHidden = false;
    els.selection.textContent = `Retreat ${unit.name} from ${areaName(state.battle.area)}.`;
    els.areaDetail.textContent = "Choose one of the highlighted legal destinations on the map. The enemy entry area is prohibited.";
    if (els.battleDialog?.open) els.battleDialog.close();
    document.querySelector("#board")?.scrollIntoView({ block: "center", inline: "center" });
    render();
  }

  async function chooseVoluntaryRetreatTarget(areaId) {
    if (!voluntaryRetreatTargeting() || !areaId) return;
    const { unitId, targets } = voluntaryRetreatSelection;
    const unit = state.units[unitId];
    if (!targets.includes(areaId)) {
      state.selectedArea = areaId;
      els.selection.textContent = `${areaName(areaId)} is not a legal retreat for ${unit.name}.`;
      els.areaDetail.textContent = areas[state.battle.area]?.links?.includes(areaId)
        ? `Blocked: ${voluntaryRetreatBlockReason(state.battle, unit, areaId) || "not a legal destination"}.`
        : "Retreats must move to an adjacent highlighted area.";
      render();
      return;
    }

    voluntaryRetreatSelection = null;
    state.selectedUnit = null;
    state.selectedArea = areaId;
    await battleAction("retreat", unitId, areaId);
  }

  function cancelVoluntaryRetreatTargeting() {
    voluntaryRetreatSelection = null;
    state.selectedUnit = null;
    state.selectedArea = state.battle?.area || null;
    render();
  }

  function legalVoluntaryRetreatTargets(battle, unit) {
    if (!battle || !unit) return [];

    return areas[battle.area].links.filter((areaId) => !voluntaryRetreatBlockReason(battle, unit, areaId));
  }

  function forcedRetreatUnits(battle) {
    if (!battle) return [];
    return [...(battle.attackers || []), ...(battle.defenders || [])]
      .filter((unitId, index, ids) => ids.indexOf(unitId) === index)
      .map((unitId) => state.units[unitId])
      .filter((unit) =>
        unit &&
        unit.owner === battle.retreating &&
        unit.location === battle.area &&
        currentStrength(unit) > 0
      );
  }

  function voluntaryRetreatBlockReason(battle, unit, areaId) {
    if (!areas[areaId] || areas[areaId].sea) return "sea";
    if (areaId === "germania" && unit.type !== "german") return "germania";
    if (areaUnits(areaId).some((occupant) => occupant.owner !== unit.owner)) return "enemy or neutral occupied";
    if (enemyBattleEntryAreas(battle, unit.owner).includes(areaId)) return "enemy entry area";

    const capacity = borderCapacity(borderType(battle.area, areaId));
    const used = battle.crossings?.[`${battle.area}->${areaId}`] || 0;
    if (capacity && used + 1 > capacity) return "border capacity";
    return null;
  }

  function enemyBattleEntryAreas(battle, owner) {
    const opposingIds = [
      ...(battle.attackers || []),
      ...(battle.defenders || []),
      ...(battle.retreated || []),
      ...(battle.fort || []),
      ...Object.keys(battle.entries || {})
    ].filter((unitId, index, ids) => ids.indexOf(unitId) === index && state.units[unitId]?.owner !== owner);
    const origins = opposingIds.map((unitId) => battle.entries?.[unitId]).filter(Boolean);
    if (owner === battle.defender && battle.mainOrigin) origins.push(battle.mainOrigin);
    return [...new Set(origins)];
  }

  function regroupingOnMap() {
    return Boolean(state.regrouping && state.battle?.phase === "regroup");
  }

  function retreatingOnMap() {
    return Boolean(state.retreating && state.battle?.phase === "retreat");
  }

  function battleMapMode() {
    return regroupingOnMap() || retreatingOnMap();
  }

  function canBattleMapUnit(unit) {
    if (regroupingOnMap()) return canRegroupUnit(unit);
    if (retreatingOnMap()) return canForcedRetreatUnit(unit);
    return false;
  }

  function canRegroupUnit(unit) {
    return Boolean(
      regroupingOnMap() &&
      unit &&
      unit.owner === state.battle.winner &&
      unit.location === state.battle.area &&
      currentStrength(unit) > 0
    );
  }

  function canForcedRetreatUnit(unit) {
    return Boolean(
      retreatingOnMap() &&
      unit &&
      unit.owner === state.battle.retreating &&
      unit.location === state.battle.area &&
      currentStrength(unit) > 0
    );
  }

  function startMapRegroup() {
    if (!state.battle || state.battle.phase !== "regroup") return;

    state.regrouping = true;
    state.selectedUnit = null;
    state.selectedArea = state.battle.area;
    els.selection.textContent = `Regroup from ${areaName(state.battle.area)}. Select or drag victorious units to adjacent legal areas.`;
    els.areaDetail.textContent = "Click Finished Regroup when done.";
    if (els.battleDialog?.open) els.battleDialog.close();
    document.querySelector("#board")?.scrollIntoView({ block: "center", inline: "center" });
    render();
  }

  async function finishRegroup() {
    state.regroupUnit = null;
    state.selectedUnit = null;
    await battleAction("regroup");
  }

  function startMapRetreat() {
    if (!state.battle || state.battle.phase !== "retreat") return;

    state.retreating = true;
    state.selectedUnit = null;
    state.selectedArea = state.battle.area;
    els.selection.textContent = `Retreat from ${areaName(state.battle.area)}. Select or drag defeated units to adjacent legal areas.`;
    els.areaDetail.textContent = "Click Retreat Complete when the defeated army has left the battle area.";
    if (els.battleDialog?.open) els.battleDialog.close();
    document.querySelector("#board")?.scrollIntoView({ block: "center", inline: "center" });
    render();
  }

  async function finishBattleMapMode() {
    if (retreatingOnMap()) {
      state.regroupUnit = null;
      state.selectedUnit = null;
      await battleAction("finish_retreat");
      return;
    }

    await finishRegroup();
  }

  function legalRegroupTargets(battle, unit) {
    return areas[battle.area].links.filter((areaId) => !regroupBlockReason(battle, areaId, unit));
  }

  function regroupBlockReason(battle, areaId, unit) {
    if (!areas[areaId] || areas[areaId].sea) return "sea";
    if (isContestedArea(areaId)) return "pending battle";
    if (areaUnits(areaId).some((unit) => unit.owner !== battle.winner)) return "enemy or neutral occupied";
    if (areaId === "germania" && unit?.type !== "german") return "germania";

    const capacity = borderCapacity(borderType(battle.area, areaId));
    const used = battle.crossings?.[`${battle.area}->${areaId}`] || 0;
    if (capacity && used + 1 > capacity) return "border capacity";
    return null;
  }

  function isContestedArea(areaId) {
    const owners = new Set(areaUnits(areaId).map((unit) => unit.owner).filter((owner) => owner !== "neutral"));
    return owners.has("roman") && owners.has("barbarian");
  }

  function battleUnitCard(unitId, battle, selected = false, zone = "field") {
    const unit = state.units[unitId];
    if (!unit) return "";
    const rollAnimating = diceAnimationRollingFor(battle, battle.awaitingRollAcknowledgement);
    const beforeRollUnit = rollAnimating ? diceRollAnimation?.beforeUnits?.[unitId] : null;
    const rollReviewElimination = battle.rollReviewEliminations?.[unitId];
    const reviewingElimination = Boolean(rollReviewElimination && !rollAnimating);
    const displayUnit = beforeRollUnit
      ? { ...unit, ...beforeRollUnit }
      : (rollReviewElimination ? { ...unit, step: rollReviewElimination.step } : unit);
    const active = unitId === battle.activeUnit;
    const hitTarget = !rollAnimating && (battle.pendingHits?.targetIds || []).includes(unitId);
    const awaitingRoll = battle.awaitingRollAcknowledgement === unitId;
    const manualRollReview = awaitingRoll && !solitaireBotRoll(battle, unitId);
    const canAct = battle.phase === "field" && active && !battle.pendingHits && !battle.awaitingRollAcknowledgement;
    const phaseSelectable = (
      (battle.phase === "regroup" && unit.owner === battle.winner) ||
      (battle.phase === "retreat" && unit.owner === battle.retreating)
    ) && unit.location === battle.area && currentStrength(unit) > 0;
    const selectable = hitTarget || phaseSelectable;
    const inFort = zone === "fort" || (battle.fort || []).includes(unitId);
    const fired = (battle.fired || []).includes(unitId);
    const rollDice = battleUnitRollDice(unitId, battle, unit);
    const halfHit = rollAnimating ? diceRollAnimation?.beforeHalfHits?.[unitId] : battle.halfHits?.[unitId];
    const halfHitSource = inFort ? "Fort defense" : battle.area === "helvetii" && unit.owner === battle.defender ? "Alps defense" : "Half hit";
    const status = reviewingElimination ? "Eliminated" : rollAnimating && awaitingRoll ? "Rolling dice" : hitTarget ? "Choose for hit" : manualRollReview ? "Roll result" : awaitingRoll ? "Fired" : active ? "Acting now" : fired ? "Fired" : zone === "reserve" ? "Reserve" : zone === "fort" ? "In fort" : "Ready";
    const retreatTargets = canAct && !inFort ? legalVoluntaryRetreatTargets(battle, unit) : [];
    const actions = canAct ? `
      <div class="battle-unit-actions">
        <button type="button" class="battle-unit-action action-fire" data-battle-action="fire" data-unit-id="${unitId}">Fire</button>
        ${inFort ? "" : `<button type="button" class="battle-unit-action action-retreat" data-battle-action="retreat" data-unit-id="${unitId}"${retreatTargets.length ? "" : " disabled title=\"No legal retreat area\""}>Retreat</button>`}
        ${canEnterBattleFort(unit, battle) ? `<button type="button" class="battle-unit-action action-fort" data-battle-action="fort" data-unit-id="${unitId}">Enter ${titleCase(areas[battle.area].fort.name)}</button>` : ""}
      </div>
    ` : "";

    return `
      <article class="battle-unit-card owner-${unit.owner}${active || selected ? " is-active" : ""}${canAct ? " can-act" : ""}${manualRollReview ? " is-awaiting-roll" : ""}${selectable ? " is-selectable" : ""}${hitTarget ? " is-hit-target" : ""}${fired ? " is-fired" : ""}${reviewingElimination ? " is-roll-eliminated" : ""}" data-battle-unit="${unitId}"${selectable ? " role=\"button\" tabindex=\"0\"" : ""}>
        <div class="battle-unit-body">
          <div class="battle-unit-counter" title="${reviewingElimination ? `${unit.name}: eliminated by this fire result` : `${unit.name}: current strength ${currentStrength(displayUnit)}`}">
            ${unitCounterMarkup(displayUnit, { halfHitOverride: halfHit })}
          </div>
          <div class="battle-unit-info">
            <span class="battle-unit-status"><span>${status}</span></span>
            <strong>${unit.name}</strong>
            <div class="battle-unit-stats">
              <span><b>${unit.initiative}</b> Initiative</span>
              <span><b>${unit.fire}</b> Battle Rating</span>
              ${halfHit ? `<span class="battle-half-hit"><b>${halfHit}/2</b> ${halfHitSource}</span>` : ""}
            </div>
          </div>
          ${rollDice}
        </div>
        ${hitTarget ? `<span class="battle-hit-target-prompt">Assign hit to ${unit.name}</span>` : ""}
        ${actions}
      </article>
    `;
  }

  function battleUnitRollDice(unitId, battle, unit) {
    if (battle.awaitingRollAcknowledgement !== unitId) return "";
    if (solitaireBotRoll(battle, unitId)) return "";

    const result = battleFireResult(battle, unitId);
    if (!result) return "";

    const rolling = diceAnimationRollingFor(battle, unitId);
    const rolls = rolling ? diceRollAnimation.displayRolls : result.rolls || [];
    if (!rolls.length) return "";

    const hitCount = Number(result.hits || 0);
    const label = rolling ? `${unit.name} is rolling` : `${unit.name} rolled ${rolls.join(", ")}; ${hitCount} hit${hitCount === 1 ? "" : "s"}`;
    const dice = rolls.map((roll) => {
      const hit = !rolling && Number(roll) <= Number(unit.fire);
      const title = rolling ? "Rolling" : `${roll}: ${hit ? "hit" : "miss"}`;
      return `<span class="battle-roll-die${rolling ? " is-rolling" : ""}${hit ? " is-hit" : ""}" title="${title}">${roll}</span>`;
    }).join("");

    const acknowledgement = !rolling && !battle.pendingHits
      ? `<button type="button" class="battle-roll-acknowledge" data-battle-action="acknowledge_roll" data-unit-id="${unitId}">OK</button>`
      : "";

    return `
      <div class="battle-roll-result${rolling ? " is-rolling" : " is-settled"}" role="status" aria-label="${label}">
        <div class="battle-roll-dice" role="img" aria-hidden="true">${dice}</div>
        <strong>${rolling ? "Rolling..." : hitCount ? `${hitCount} hit${hitCount === 1 ? "" : "s"}` : "No hits"}</strong>
        ${acknowledgement}
      </div>
    `;
  }

  function solitaireBotRoll(battle, unitId) {
    return state.mode === "solitaire" && state.units[unitId]?.owner === "barbarian";
  }

  function reviewSolitaireBotRoll(battle) {
    const unitId = battle.awaitingRollAcknowledgement;
    if (!unitId || !solitaireBotRoll(battle, unitId)) {
      resetBotRollReview();
      return;
    }

    const result = [...(battle.actionResults || [])].reverse().find((action) => (
      action.type === "fire" &&
      action.unitId === unitId &&
      Number(action.round || battle.round) === Number(battle.round)
    ));
    if (!result) return;

    const key = [battle.area, battle.round, unitId, (result.rolls || []).join(",")].join(":");
    if (botRollReview?.key !== key) {
      resetBotRollReview();
      const hits = Number(result.hits || 0);
      botRollReview = { key, unitId, shownAt: Date.now(), acknowledgementTimer: null, hideTimer: null };
      if (els.battleRollToast) {
        els.battleRollToast.textContent = hits
          ? `${result.unitName} scored ${hits} hit${hits === 1 ? "" : "s"}`
          : `${result.unitName} scored no hits`;
        els.battleRollToast.classList.toggle("is-hit", hits > 0);
        els.battleRollToast.hidden = false;
        window.requestAnimationFrame(() => els.battleRollToast.classList.add("is-visible"));
        botRollReview.hideTimer = window.setTimeout(hideBotRollToast, botRollToastDuration);
      }
    }

    // A Roman player may still need to choose which equal-strength unit takes
    // a hit. Preserve that choice, then acknowledge the Barbarian roll without
    // requiring an additional OK click.
    if (battle.pendingHits || botRollReview.acknowledgementTimer) return;

    const elapsed = Date.now() - botRollReview.shownAt;
    const delay = Math.max(0, botRollToastDuration - elapsed);
    botRollReview.acknowledgementTimer = window.setTimeout(async () => {
      const currentUnitId = state.battle?.awaitingRollAcknowledgement;
      botRollReview.acknowledgementTimer = null;
      if (currentUnitId !== unitId || state.battle?.pendingHits) return;
      await battleAction("acknowledge_roll", unitId);
    }, delay);
  }

  function hideBotRollToast() {
    if (!els.battleRollToast) return;
    els.battleRollToast.classList.remove("is-visible");
    window.setTimeout(() => {
      if (els.battleRollToast.classList.contains("is-visible")) return;
      els.battleRollToast.hidden = true;
    }, 180);
  }

  function resetBotRollReview() {
    if (botRollReview?.acknowledgementTimer) window.clearTimeout(botRollReview.acknowledgementTimer);
    if (botRollReview?.hideTimer) window.clearTimeout(botRollReview.hideTimer);
    botRollReview = null;
    if (!els.battleRollToast) return;
    els.battleRollToast.hidden = true;
    els.battleRollToast.classList.remove("is-visible", "is-hit");
    els.battleRollToast.textContent = "";
  }

  function battleLastActionText(action) {
    if (action.type === "reserves") {
      const names = (action.unitNames || []).join(", ");
      return `Reserves enter the battle: ${names}. These units may now act and suffer hits.`;
    }
    if (action.type === "fire") {
      const rolls = (action.rolls || []).join(", ");
      const hits = action.hits || 0;
      const applied = action.appliedHits;
      const reduction = Number.isInteger(applied) && applied !== hits ? `, ${applied} step loss${applied === 1 ? "" : "es"} applied` : "";
      return `${action.unitName} rolled ${rolls || "no dice"}: ${hits} hit${hits === 1 ? "" : "s"}${reduction}.`;
    }
    if (action.type === "retreat") return `${action.unitName} retreated to ${action.targetName}.`;
    if (action.type === "fort") return `${action.unitName} withdrew into ${action.fortName}.`;
    return `${action.unitName} acted.`;
  }

  function battleActionHistory(battle) {
    const rollingUnitId = diceAnimationRollingFor(battle, battle.awaitingRollAcknowledgement)
      ? battle.awaitingRollAcknowledgement
      : null;
    const actions = (battle.actionResults || []).filter((action) => !(
      rollingUnitId &&
      action.type === "fire" &&
      action.unitId === rollingUnitId &&
      Number(action.round || battle.round) === Number(battle.round)
    )).slice(-4);
    if (!actions.length) return "";
    let lastRound = null;
    const lines = actions.flatMap((action) => {
      const round = action.round || battle.round;
      const actionClass = action.type === "reserves" ? " class=\"battle-reserve-announcement\"" : "";
      const actionLine = `<span${actionClass}>${battleLastActionText(action)}</span>`;
      if (round === lastRound) return [actionLine];
      lastRound = round;
      return [`<b class="battle-round-marker">Round ${round}</b>`, actionLine];
    });

    return `
      <div class="battle-action-history">
        ${lines.join("")}
      </div>
    `;
  }

  function renderModeControls() {
    const commitButton = document.querySelector("#commit-card");
    const revealButton = document.querySelector("#reveal-cards");
    const playerButtons = document.querySelectorAll(".player-button");
    const hotseat = state.mode === "hotseat";
    els.hotseatControls.hidden = !hotseat;

    if (hotseat) {
      playerButtons.forEach((button) => {
        button.disabled = !state.revealed && Boolean(state.committed[button.dataset.player]);
      });
      commitButton.disabled = Boolean(state.movement) || Boolean(state.battle) || Boolean(state.revealed) || !state.selectedCard;
      revealButton.disabled = Boolean(state.movement) || Boolean(state.battle) || Boolean(state.revealed) || !state.committed.roman || !state.committed.barbarian;
    }
  }

  function renderActionButtons() {
    const battleButton = document.querySelector("#resolve-battles");
    const endTurnButton = document.querySelector("#end-turn");
    const unresolvedBattles = contestedAreas().length;
    battleButton.classList.toggle("is-active", Boolean(state.battle));
    battleButton.disabled = Boolean(state.battle) || unresolvedBattles === 0;

    if (state.gameOver) {
      battleButton.disabled = true;
      endTurnButton.textContent = "Campaign Complete";
      endTurnButton.disabled = true;
      endTurnButton.title = `${state.gameOver.result}: ${state.gameOver.vp} Roman VP.`;
      return;
    }

    if (state.endTurn?.phase === "romanWintering") {
      endTurnButton.textContent = "Winter Quarters Active";
      endTurnButton.disabled = true;
      endTurnButton.title = "Select highlighted Roman legions directly on the map.";
      battleButton.disabled = true;
      return;
    }

    if (state.endTurn?.phase === "romanReplacements") {
      endTurnButton.textContent = "Roman Replacements";
      endTurnButton.disabled = true;
      endTurnButton.title = "Complete Roman replacements and reorganization above the map.";
      battleButton.disabled = true;
      return;
    }

    if (state.endTurn?.phase === "romanSupplyProduction") {
      endTurnButton.textContent = "Supply Production";
      endTurnButton.disabled = true;
      endTurnButton.title = "Review Roman supply production above the map.";
      battleButton.disabled = true;
      return;
    }

    if (state.endTurn?.phase === "romanReinforcements") {
      endTurnButton.textContent = "Roman Reinforcements";
      endTurnButton.disabled = true;
      endTurnButton.title = "Build new Roman legions or continue above the map.";
      battleButton.disabled = true;
      return;
    }

    if (state.movement) {
      endTurnButton.textContent = "Finish Movement";
      endTurnButton.disabled = Boolean(state.battle) || unresolvedBattles > 0;
      endTurnButton.title = endTurnButton.disabled ? "Resolve all battles before finishing movement." : "Finish this movement action and discard its card.";
      return;
    }

    const remaining = remainingCardsForTurn();
    endTurnButton.textContent = "End Turn";
    endTurnButton.disabled = Boolean(state.battle) || remaining > 0;
    if (state.battle) {
      endTurnButton.title = "Finish the current battle before ending the turn.";
    } else if (remaining > 0) {
      endTurnButton.title = `Play the remaining ${remaining} card${remaining === 1 ? "" : "s"} before ending the turn.`;
    } else {
      endTurnButton.title = "Score the year and deal the next hand.";
    }
  }

  function remainingCardsForTurn() {
    if (state.mode === "hotseat") {
      return (state.hands?.roman?.length || 0) + (state.hands?.barbarian?.length || 0);
    }
    return state.hands?.roman?.length || 0;
  }

  function showCampaignResult() {
    if (!state.gameOver) return;

    const report = state.gameOver.postGameReport;
    const reportNotice = report?.path
      ? `\n\nA post-game session report was written to:\n${report.path}`
      : report?.error
        ? `\n\nThe post-game session report could not be written: ${report.error}`
        : "";
    showResultDialog(
      state.gameOver.result,
      `The campaign has ended with ${state.gameOver.vp} Roman victory points.${reportNotice}`
    );
  }

  function renderWinterQuarters() {
    if (!els.winterQuartersPanel) return;
    if (state.endTurn?.phase !== "romanWintering") {
      els.winterQuartersPanel.hidden = true;
      setWinterQuartersError();
      return;
    }

    els.winterQuartersPanel.hidden = false;
    const harvestRoll = state.endTurn.harvestRoll;
    const garrisonLimit = state.endTurn.garrisonLimit;
    const harvestQuality = harvestRoll === 1 ? "Poor" : harvestRoll === 6 ? "Bountiful" : "Normal";
    const selected = winteringUnitIds();
    const supplyCost = selected.filter((unitId) => unitId !== "legion_x").length;
    els.winterQuartersSummary.textContent = `${harvestQuality} Harvest: up to ${garrisonLimit} legion${garrisonLimit === 1 ? "" : "s"} per area; Caesar does not count against the limit.`;
    els.winterQuartersSelection.textContent = selected.length
      ? `${selected.length} selected · ${supplyCost} supply`
      : "No legions selected · 0 supply";
  }

  function winterQuartersActive() {
    return state.endTurn?.phase === "romanWintering";
  }

  function winteringUnitIds() {
    if (!winterQuartersActive()) return [];
    state.endTurn.winteringUnitIds ||= [];
    const eligible = new Set(state.endTurn.eligibleLegions || []);
    state.endTurn.winteringUnitIds = state.endTurn.winteringUnitIds.filter((unitId) =>
      eligible.has(unitId) && !(unitId === "legion_x" && state.caesarWintered)
    );
    return state.endTurn.winteringUnitIds;
  }

  function winterQuartersEligible(unitId) {
    return winterQuartersActive() &&
      (state.endTurn.eligibleLegions || []).includes(unitId) &&
      !(unitId === "legion_x" && state.caesarWintered);
  }

  function toggleWinteringUnit(unitId) {
    if (!winterQuartersEligible(unitId)) return;

    const selected = winteringUnitIds();
    const index = selected.indexOf(unitId);
    if (index >= 0) {
      selected.splice(index, 1);
    } else {
      const unit = state.units[unitId];
      const limit = state.endTurn.garrisonLimit;
      const selectedInArea = selected.filter((selectedId) => {
        const selectedUnit = state.units[selectedId];
        return selectedId !== "legion_x" && selectedUnit?.location === unit.location;
      }).length;
      if (unitId !== "legion_x" && selectedInArea >= limit) {
        setWinterQuartersError(`Only ${limit} legion${limit === 1 ? "" : "s"} may winter in ${areaName(unit.location)} after this harvest.`);
        return;
      }
      selected.push(unitId);
    }
    setWinterQuartersError();
    render();
  }

  function setWinterQuartersError(message = "") {
    if (!els.winterQuartersError) return;
    els.winterQuartersError.textContent = message;
    els.winterQuartersError.hidden = !message;
  }

  function renderRomanAdministration() {
    if (!els.romanAdministrationDialog || !els.romanAdministrationForm) return;
    const phase = state.endTurn?.phase;
    if (!["romanReplacements", "romanSupplyProduction", "romanReinforcements"].includes(phase)) {
      if (els.romanAdministrationDialog.open) els.romanAdministrationDialog.close();
      setRomanAdministrationError();
      return;
    }

    if (phase === "romanReplacements") {
      renderRomanReplacementOptions();
    } else if (phase === "romanSupplyProduction") {
      renderRomanSupplyProduction();
    } else {
      renderRomanReinforcementOptions();
    }
    if (!els.romanAdministrationDialog.open) els.romanAdministrationDialog.showModal();
  }

  function renderRomanReplacementOptions() {
    state.endTurn.replacementSteps ||= {};
    const choices = state.endTurn.replacementSteps;
    const options = state.endTurn.replacementOptions || [];
    const cost = Object.values(choices).reduce((sum, value) => sum + Number(value || 0), 0);
    els.romanAdministrationTitle.textContent = "Roman Replacements &\nReorganization";
    els.romanAdministrationOptions.innerHTML = options.map((option) => {
      const steps = Number(choices[option.id] || 0);
      return administrationChoiceHtml({
        kind: "replacement",
        id: option.id,
        name: option.name,
        detail: `${option.locationName} · ${option.currentStrength} → ${option.currentStrength + steps}`,
        value: steps,
        maximum: option.maximumSteps,
        valueLabel: `${steps} step${steps === 1 ? "" : "s"}`
      });
    }).join("");
    els.romanAdministrationStatus.textContent = `${cost} supply selected · ${state.supply - cost} remaining`;
    els.romanAdministrationContinue.textContent = cost ? "Buy Replacements" : "Skip Replacements";
    bindRomanAdministrationButtons();
  }

  function renderRomanReinforcementOptions() {
    state.endTurn.reinforcementBuilds ||= {};
    const choices = state.endTurn.reinforcementBuilds;
    const options = state.endTurn.reinforcementOptions || [];
    const cost = Object.values(choices).reduce((sum, value) => sum + Number(value || 0), 0);
    const builds = Object.values(choices).filter((value) => Number(value) > 0).length;
    const limit = state.endTurn.reinforcementLimit || 1;
    els.romanAdministrationTitle.textContent = "Roman Reinforcements";
    els.romanAdministrationOptions.innerHTML = options.map((option) => {
      const strength = Number(choices[option.id] || 0);
      const buildUnavailable = builds >= limit && strength === 0;
      return administrationChoiceHtml({
        kind: "reinforcement",
        id: option.id,
        name: option.name,
        detail: "Force Pool",
        value: strength,
        maximum: option.maximumStrength,
        valueLabel: strength ? `strength ${strength}` : "not built",
        disabled: buildUnavailable
      });
    }).join("");
    els.romanAdministrationStatus.textContent = `${builds} of ${limit} legion${limit === 1 ? "" : "s"} · ${cost} supply · ${state.supply - cost} remaining`;
    els.romanAdministrationContinue.textContent = builds ? "Build Reinforcements" : "Skip Reinforcements";
    bindRomanAdministrationButtons();
  }

  function renderRomanSupplyProduction() {
    const production = state.endTurn.supplyProduction || {};
    const sources = production.sources || [];
    const produced = Number(production.produced || 0);
    const gained = Number(production.gained || 0);
    const before = Number(production.before || 0);
    const after = Number(production.after ?? state.supply ?? 0);

    els.romanAdministrationTitle.textContent = "Roman Supply\nProduction";
    els.romanAdministrationOptions.innerHTML = `
      <div class="roman-supply-production-summary">
        <div class="roman-supply-production-sources">
          ${sources.map((source) => `
            <span class="roman-supply-production-source">
              <strong>${source.name}</strong>
              <b>+${source.amount}</b>
            </span>
          `).join("")}
        </div>
        <div class="roman-supply-production-total">
          <span>${before}</span>
          <b>+${gained}</b>
          <strong>${after} supply</strong>
        </div>
      </div>`;
    els.romanAdministrationStatus.textContent = production.capped
      ? `${produced} produced · ${gained} gained due to the 19-supply maximum`
      : `${produced} supply produced`;
    els.romanAdministrationContinue.textContent = "OK";
  }

  function administrationChoiceHtml({ kind, id, name, detail, value, maximum, valueLabel, disabled = false }) {
    const unit = state.units[id];
    return `
      <div class="roman-administration-choice${disabled ? " is-disabled" : ""}"${disabled ? " aria-disabled=\"true\"" : ""}>
        <span class="roman-administration-counter" title="${name}">
          ${unit ? unitCounterMarkup(unit, { showStats: false, showStrength: false }) : ""}
        </span>
        <div class="roman-administration-choice-body">
          <span class="roman-administration-choice-label"><strong>${name}</strong><small>${detail}</small></span>
          <div class="roman-administration-stepper">
            <button type="button" aria-label="Decrease ${name}" data-administration-kind="${kind}" data-unit-id="${id}" data-delta="-1"${value <= 0 ? " disabled" : ""}>−</button>
            <output>${valueLabel}</output>
            <button type="button" aria-label="Increase ${name}" data-administration-kind="${kind}" data-unit-id="${id}" data-delta="1"${disabled || value >= maximum ? " disabled" : ""}>+</button>
          </div>
        </div>
      </div>`;
  }

  function bindRomanAdministrationButtons() {
    els.romanAdministrationOptions.querySelectorAll("[data-administration-kind]").forEach((button) => {
      button.addEventListener("click", () => adjustRomanAdministrationChoice(
        button.dataset.administrationKind,
        button.dataset.unitId,
        Number(button.dataset.delta)
      ));
    });
  }

  function adjustRomanAdministrationChoice(kind, unitId, delta) {
    const replacement = kind === "replacement";
    const key = replacement ? "replacementSteps" : "reinforcementBuilds";
    const optionKey = replacement ? "replacementOptions" : "reinforcementOptions";
    const maximumKey = replacement ? "maximumSteps" : "maximumStrength";
    state.endTurn[key] ||= {};
    const option = (state.endTurn[optionKey] || []).find((candidate) => candidate.id === unitId);
    if (!option) return;

    const oldValue = Number(state.endTurn[key][unitId] || 0);
    const newValue = Math.max(0, Math.min(option[maximumKey], oldValue + delta));
    const currentCost = Object.values(state.endTurn[key]).reduce((sum, value) => sum + Number(value || 0), 0);
    if (newValue > oldValue && currentCost >= state.supply) {
      setRomanAdministrationError("No additional supply is available.");
      return;
    }
    if (!replacement && oldValue === 0 && newValue > 0) {
      const builds = Object.values(state.endTurn[key]).filter((value) => Number(value) > 0).length;
      if (builds >= (state.endTurn.reinforcementLimit || 1)) {
        setRomanAdministrationError(`Only ${state.endTurn.reinforcementLimit || 1} new legion${state.endTurn.reinforcementLimit === 1 ? "" : "s"} may be built this year.`);
        return;
      }
    }

    state.endTurn[key][unitId] = newValue;
    setRomanAdministrationError();
    renderRomanAdministration();
  }

  function setRomanAdministrationError(message = "") {
    if (!els.romanAdministrationError) return;
    els.romanAdministrationError.textContent = message;
    els.romanAdministrationError.hidden = !message;
  }

  function renderUndoButton() {
    const button = document.querySelector("#undo-move");
    button.disabled = state.diceRolledThisTurn || !(state.undoStack?.length);
  }

  function renderPieceToggle() {
    const button = document.querySelector("#toggle-pieces");
    button.textContent = piecesHidden ? "Show Units" : "Hide Units";
    button.setAttribute("aria-pressed", piecesHidden ? "true" : "false");
    button.disabled = winterQuartersActive() || revoltTargeting() || voluntaryRetreatTargeting() || mainForceTargeting();
    button.title = winterQuartersActive()
      ? "Units remain visible while choosing winter quarters."
      : revoltTargeting()
        ? "Units remain visible while choosing a revolt target."
        : voluntaryRetreatTargeting()
          ? "Units remain visible while choosing a retreat destination."
          : mainForceTargeting()
            ? "Units remain visible while choosing the main force."
        : "";
  }

  function togglePieces() {
    if (winterQuartersActive() || revoltTargeting() || voluntaryRetreatTargeting() || mainForceTargeting()) return;
    piecesHidden = !piecesHidden;
    render();
  }

  function renderLog() {
    els.log.innerHTML = state.log.map((entry) => `<li>${entry}</li>`).join("");
  }

  function normalizeLoadedState() {
    if (state.movement) {
      state.movement.units ||= {};
      state.movement.crossings ||= {};
    }
    state.neutralActivationCards ||= {};
    state.neutralActivationCards.roman ||= [];
    state.neutralActivationCards.barbarian ||= [];
    state.options ||= {};
    state.options.yearlyObjectives ||= false;
    state.options.historicalReinforcements ||= false;
    state.options.postGameReport ||= false;
    state.campaignLog ||= [];
    state.campaignSnapshots ||= [];
    state.yearlyObjectiveProgress ||= {};
    state.yearlyObjectiveHistory ||= [];
    state.dragArea = null;
    state.targetingAction ||= null;
    state.undoStack ||= [];
    state.diceRolledThisTurn ||= false;
    state.gameSessionId ||= null;
    if (winterQuartersActive()) {
      state.selectedUnit = null;
      state.endTurn.winteringUnitIds ||= [];
      piecesHidden = false;
    }
    if (state.endTurn?.phase === "romanReplacements") state.endTurn.replacementSteps ||= {};
    if (state.endTurn?.phase === "romanReinforcements") state.endTurn.reinforcementBuilds ||= {};
    if (!state.battle) {
      state.regrouping = false;
      state.retreating = false;
      battleTransitionReview = null;
      voluntaryRetreatSelection = null;
      if (els.battleTransitionDialog?.open) els.battleTransitionDialog.close();
    }
    if (state.battle) {
      state.battle.acted ||= [];
      state.battle.actionResults ||= [];
      state.battle.reserves ||= [];
      state.battle.fort ||= [];
      state.battle.halfHits ||= {};
      state.battle.retreated ||= [];
      state.battle.crossings ||= {};
    }
    if (state.regroupUnit && (!state.battle || state.units[state.regroupUnit]?.location !== state.battle.area)) {
      state.regroupUnit = null;
    }
  }

  async function setMode(mode) {
    state.mode = mode;
    state.active = "roman";
    state.selectedCard = null;
    state.committed = { roman: null, barbarian: null };
    state.revealed = false;
    state.movement = null;
    state.battle = null;
    state.currentAction = null;
    handHidden = false;
    zoomedCardId = null;
    log(`Mode changed to ${modeName()}. Dealing a fresh hand for this mode.`);
    await dealCards();
  }

  async function changeMode(mode) {
    if (mode === state.mode) return;
    if (!window.confirm("Changing modes deals fresh hands for the current year. Continue?")) {
      return;
    }
    await setMode(mode);
  }

  function exportGame() {
    els.exportText.value = exportedGameJson();
    els.exportDialog.showModal();
  }

  function exportedGameJson() {
    const exported = structuredClone(state);
    exported.gameSessionId = null;
    exported.dragArea = null;
    return JSON.stringify(exported, null, 2);
  }

  function downloadExport(contents = els.exportText.value || exportedGameJson()) {
    const blob = new Blob([contents], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    const year = (gameData.years[state.turn] || `turn-${state.turn + 1}`).toLowerCase().replaceAll(" ", "-");
    link.href = url;
    link.download = `caesars-gallic-war-${year}.json`;
    document.body.append(link);
    link.click();
    link.remove();
    URL.revokeObjectURL(url);
  }

  function openImportDialog() {
    els.importFile.value = "";
    els.importText.value = "";
    setImportError();
    els.importDialog.showModal();
  }

  async function loadImportFile(file) {
    if (!file) return;
    try {
      els.importText.value = await file.text();
      setImportError();
    } catch (_error) {
      setImportError("That file could not be read.");
    }
  }

  async function importGame(event) {
    event.preventDefault();
    try {
      const imported = validateImportedGame(JSON.parse(els.importText.value));
      imported.gameSessionId = null;
      const result = await postJson("/game_sessions", { state: imported });
      state = result.state;
      state.gameSessionId = result.game_session_id;
      normalizeLoadedState();
      log("Imported game loaded.");
      els.importDialog.close();
      render();
    } catch (error) {
      setImportError(error instanceof SyntaxError ? "The imported file is not valid JSON." : error.message);
    }
  }

  function validateImportedGame(imported) {
    if (!imported || typeof imported !== "object" || Array.isArray(imported)) throw new Error("The imported file does not contain a game.");
    if (!Number.isInteger(imported.turn) || imported.turn < 0 || imported.turn >= gameData.years.length) throw new Error("The imported game has an invalid turn.");
    if (!["hotseat", "solitaire", "ai"].includes(imported.mode)) throw new Error("The imported game has an invalid play mode.");
    if (!imported.units || typeof imported.units !== "object" || Array.isArray(imported.units)) throw new Error("The imported game is missing its units.");
    if (!imported.hands || !Array.isArray(imported.hands.roman) || !Array.isArray(imported.hands.barbarian)) throw new Error("The imported game is missing its hands.");
    if (!Array.isArray(imported.log)) throw new Error("The imported game is missing its log.");
    return imported;
  }

  function setImportError(message = "") {
    els.importError.textContent = message;
    els.importError.hidden = !message;
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

  function closeGameMenu() {
    els.gameMenu?.removeAttribute("open");
  }

  function closeModeMenu() {
    els.modeMenu?.removeAttribute("open");
  }

  function closeZoomMenu() {
    els.zoomMenu?.removeAttribute("open");
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
    const responseText = await response.text();
    let payload;
    try {
      payload = JSON.parse(responseText);
    } catch (_error) {
      const status = `${response.status} ${response.statusText}`.trim();
      throw new Error(response.ok ? "The server returned an invalid response." : `Server request failed (${status}).`);
    }
    if (!response.ok) throw new Error(payload.error || "Request failed.");
    return payload;
  }

  document.querySelector("#new-game").addEventListener("click", () => {
    closeGameMenu();
    requestNewGame();
  });
  document.querySelector("#commit-card").addEventListener("click", () => commitCard());
  document.querySelector("#reveal-cards").addEventListener("click", () => revealCards());
  els.resultDialog?.addEventListener("close", showNextResultDialog);
  els.turnDialog?.addEventListener("cancel", (event) => event.preventDefault());
  els.turnDialog?.addEventListener("close", () => setHandTrayTurnLocked(false));
  els.acknowledgeTurn?.addEventListener("click", acknowledgeTurnAnnouncement);
  els.botActionReviewDialog?.addEventListener("cancel", (event) => event.preventDefault());
  els.advanceBotActionReview?.addEventListener("click", advanceBotActionReview);
  els.botActionReviewDragHandle?.addEventListener("pointerdown", beginBotActionReviewDrag);
  els.botActionReviewDragHandle?.addEventListener("pointermove", moveBotActionReviewDialog);
  els.botActionReviewDragHandle?.addEventListener("pointerup", endBotActionReviewDrag);
  els.botActionReviewDragHandle?.addEventListener("pointercancel", endBotActionReviewDrag);
  els.battleTransitionDialog?.addEventListener("cancel", (event) => event.preventDefault());
  els.battleTransitionForm?.addEventListener("submit", continueToNextBattle);
  els.cancelRevoltTarget?.addEventListener("click", () => revoltTargetSelection?.settle(false));
  els.cancelRetreatTarget?.addEventListener("click", cancelVoluntaryRetreatTargeting);
  els.cancelMainForceTarget?.addEventListener("click", () => mainForceSelection?.settle(false));
  els.mainForceTargetDragHandle?.addEventListener("pointerdown", beginMainForceTargetDrag);
  els.mainForceTargetDragHandle?.addEventListener("pointermove", moveMainForceTargetPanel);
  els.mainForceTargetDragHandle?.addEventListener("pointerup", endMainForceTargetDrag);
  els.mainForceTargetDragHandle?.addEventListener("pointercancel", endMainForceTargetDrag);
  els.romanAdministrationDialog?.addEventListener("cancel", (event) => event.preventDefault());
  els.battleDialog?.addEventListener("cancel", (event) => {
    if (state?.battle) event.preventDefault();
  });
  els.playModeButtons.forEach((button) => button.addEventListener("click", async () => {
    closeModeMenu();
    await changeMode(button.dataset.playMode);
  }));
  els.yearlyObjectives?.addEventListener("change", (event) => changeYearlyObjectives(event.target.checked));
  els.historicalReinforcements?.addEventListener("change", (event) => changeHistoricalReinforcements(event.target.checked));
  els.postGameReport?.addEventListener("change", (event) => changePostGameReport(event.target.checked));
  els.animatedDice?.addEventListener("change", (event) => changeAnimatedDice(event.target.checked));
  els.movementSounds?.addEventListener("change", (event) => changeMovementSounds(event.target.checked));
  els.movementArrows?.addEventListener("change", (event) => changeMovementArrows(event.target.checked));
  document.addEventListener("click", primeGameAudio, { passive: true });
  document.querySelector("#end-turn").addEventListener("click", endTurn);
  els.finishRegroup?.addEventListener("click", finishBattleMapMode);
  document.querySelector("#undo-move").addEventListener("click", undoMove);
  document.querySelector("#toggle-pieces").addEventListener("click", togglePieces);
  els.mapZoomButtons.forEach((button) => button.addEventListener("click", () => {
    closeZoomMenu();
    setMapZoom(button.dataset.mapZoom);
  }));
  els.toggleHand?.addEventListener("click", toggleHand);
  els.toggleSidePanel?.addEventListener("click", toggleSidePanel);
  document.querySelector("#import-game").addEventListener("click", () => {
    closeGameMenu();
    openImportDialog();
  });
  document.querySelector("#export-game").addEventListener("click", () => {
    closeGameMenu();
    exportGame();
  });
  document.querySelector("#download-export").addEventListener("click", () => downloadExport());
  document.querySelector("#cancel-import").addEventListener("click", () => els.importDialog.close());
  document.querySelector("#cancel-new-game").addEventListener("click", () => els.newGameDialog.close());
  document.querySelector("#discard-new-game").addEventListener("click", startNewGameWithoutSaving);
  document.querySelector("#save-new-game").addEventListener("click", saveAndStartNewGame);
  els.importForm?.addEventListener("submit", importGame);
  els.winterQuartersForm?.addEventListener("submit", completeEndTurn);
  els.romanAdministrationForm?.addEventListener("submit", completeRomanAdministration);
  els.importFile?.addEventListener("change", (event) => loadImportFile(event.target.files?.[0]));
  document.querySelector("#resolve-battles").addEventListener("click", resolveBattles);
  els.cardZoom?.addEventListener("click", (event) => {
    if (event.target !== els.cardZoom) return;
    zoomedCardId = null;
    render();
  });
  document.addEventListener("keydown", (event) => {
    if (!mapPanDirection(event.code) || event.metaKey || event.ctrlKey || event.altKey || mapPanBlocked(event.target)) return;
    event.preventDefault();
    mapPanKeys.add(event.code);
    startMapPan();
  });
  document.addEventListener("keyup", (event) => {
    if (!mapPanDirection(event.code)) return;
    mapPanKeys.delete(event.code);
    if (!mapPanKeys.size) stopMapPan();
  });
  document.addEventListener("keydown", (event) => {
    if (event.key !== "Escape") return;
    closeGameMenu();
    closeModeMenu();
    closeZoomMenu();
    if (mainForceTargeting()) {
      mainForceSelection.settle(false);
      return;
    }
    if (voluntaryRetreatTargeting()) {
      cancelVoluntaryRetreatTargeting();
      return;
    }
    if (revoltTargeting()) {
      revoltTargetSelection.settle(false);
      return;
    }
    if (zoomedCardId) {
      zoomedCardId = null;
      render();
    }
  });
  window.addEventListener("blur", stopMapPan);
  document.addEventListener("visibilitychange", () => {
    if (document.hidden) stopMapPan();
  });
  document.addEventListener("click", (event) => {
    if (els.gameMenu?.open && !els.gameMenu.contains(event.target)) closeGameMenu();
    if (els.modeMenu?.open && !els.modeMenu.contains(event.target)) closeModeMenu();
    if (els.zoomMenu?.open && !els.zoomMenu.contains(event.target)) closeZoomMenu();
  });
  document.querySelectorAll(".player-button").forEach((button) => button.addEventListener("click", () => setActive(button.dataset.player)));

  renderMapZoomControl();
  layoutMapZoom({ preserveCenter: false });
  if (window.ResizeObserver && els.board) {
    boardResizeObserver = new ResizeObserver(() => layoutMapZoom());
    boardResizeObserver.observe(els.board);
  } else {
    window.addEventListener("resize", () => layoutMapZoom());
  }
  prepareAreaHitMap();
  newGame();
});
