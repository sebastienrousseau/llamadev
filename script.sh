#!/usr/bin/env bash
###############################################################################
# H E R M E T I C   A D V E N T U R E   Q U E S T
# "Journey Through the Seven Principles of the Emerald Tablet"
###############################################################################
# By [Your Name / Organization]
#
# This game is designed to be replayed daily, imparting Hermetic (and broadly
# esoteric) lessons each time. The user can explore new branches, practice
# daily exercises, and gradually deepen their knowledge.
#
# NOTE ON PERSISTENCE:
#   - For an out-of-the-box single session, you can ignore the optional "save"
#     file usage. By default, we track in variables only.
#   - If you want to track the user's progress across multiple sessions, see
#     the "load_game" and "save_game" functions, which read/write from a small
#     local file named .hermetic_journal. You can store day counters, knowledge,
#     or other data to this file.
###############################################################################

############################
# COLOR CONSTANTS
############################
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
RESET='\033[0m'

############################
# GLOBAL VARIABLES
############################
player_name=""
player_health=100
player_knowledge=0      # Overall measure of Hermetic understanding
player_day=1            # "Day" or session number
chapters_completed=0    # Number of Hermetic principles explored
journal_file=".hermetic_journal"  # Default save file (optional usage)

############################
# UTILITY FUNCTIONS
############################

# Safely read user input (with the ability to quit by pressing q).
safe_read() {
  read -r choice
  if [[ "$choice" =~ ^[Qq]$ ]]; then
    echo -e "${YELLOW}You have chosen to exit the game. Farewell and may wisdom guide you...${RESET}"
    save_game
    exit 0
  fi
  echo "$choice"
}

# Pause for readability
pause() {
  sleep 2
}

# Color-coded narrations
narrate() {
  echo -e "${CYAN}$1${RESET}"
}

narrate_warning() {
  echo -e "${YELLOW}$1${RESET}"
}

narrate_success() {
  echo -e "${GREEN}$1${RESET}"
}

narrate_danger() {
  echo -e "${RED}$1${RESET}"
}

narrate_magenta() {
  echo -e "${MAGENTA}$1${RESET}"
}

############################
# LOAD / SAVE (OPTIONAL)
############################
# If you want persistent progress across sessions, use these.
# Otherwise, you can ignore them or comment them out.
load_game() {
  if [[ -f "$journal_file" ]]; then
    # We expect lines like:
    # NAME=User
    # HEALTH=95
    # KNOWLEDGE=3
    # DAY=2
    # CHAPTERS=1
    source "$journal_file"
    player_name="$NAME"
    player_health="$HEALTH"
    player_knowledge="$KNOWLEDGE"
    player_day="$DAY"
    chapters_completed="$CHAPTERS"
  fi
}

save_game() {
  # Write current variables to file
  cat << EOF > "$journal_file"
NAME="$player_name"
HEALTH="$player_health"
KNOWLEDGE="$player_knowledge"
DAY="$player_day"
CHAPTERS="$chapters_completed"
EOF
}

############################
# INTRO SEQUENCE
############################
intro_sequence() {
  clear
  echo -e "${GREEN}=============================================================${RESET}"
  echo -e "${GREEN}        H E R M E T I C   A D V E N T U R E   Q U E S T       ${RESET}"
  echo -e "${GREEN}=============================================================${RESET}"
  pause
  echo -e "${MAGENTA}In the realm of Ancient Egypt, where hidden knowledge brims,${RESET}"
  echo -e "${MAGENTA}the Emerald Tablet stands as a beacon for those who seek truth.${RESET}"
  echo
  narrate_warning "Press (q) at any time to quit the game."
  echo

  # If we already have a saved game, ask if user wants to continue
  if [[ -f "$journal_file" ]]; then
    echo "A saved Hermetic Journal is detected. Load your previous progress?"
    echo -n "Enter [y/n]: "
    choice=$(safe_read)
    if [[ "$choice" =~ ^[Yy]$ ]]; then
      load_game
      echo -e "${YELLOW}Welcome back, $player_name! (Day $player_day, Knowledge $player_knowledge, Health $player_health)${RESET}"
      pause
      return
    else
      # Potentially start fresh
      rm -f "$journal_file"
    fi
  fi

  # Prompt for new user name if not loaded
  echo -n "Enter your name, Traveler of the Hidden Path: "
  player_name=$(safe_read)
  echo
  narrate "Greetings, ${player_name}. May your journey be enlightening."
  pause
}

############################
# DAILY PRACTICE CHECK
############################
daily_practice() {
  clear
  echo -e "${BLUE}================================================================${RESET}"
  echo -e "${BLUE}                      DAILY HERMETIC PRACTICE                    ${RESET}"
  echo -e "${BLUE}================================================================${RESET}"
  narrate "Each new day in your quest, you can affirm and expand your understanding by choosing a daily practice."
  echo
  narrate_warning "1) A short meditation on the Principle of Mentalism (quiet your mind, focus on Oneness)."
  narrate_warning "2) A journaling exercise on daily experiences related to 'As Above, So Below'."
  narrate_warning "3) A gratitude reflection for knowledge gained and future revelations."
  echo -n "Choose your daily practice (1,2,3): "

  choice=$(safe_read)
  case "$choice" in
    1)
      narrate "You still your thoughts, allowing the truth of the One Mind to permeate your being."
      narrate_success "You feel calm and more connected, which boosts your resilience."
      player_health=$((player_health + 5))
      player_knowledge=$((player_knowledge + 1))
      ;;
    2)
      narrate "You record your observations, noting parallels between the outer world and your inner reflections."
      narrate_success "Writing these insights clarifies your purpose, expanding your Hermetic perspective."
      player_knowledge=$((player_knowledge + 2))
      ;;
    3)
      narrate "You express gratitude for each lesson learned, acknowledging the flow of cosmic harmony."
      narrate_success "Your heart feels lighter, and your dedication grows stronger."
      player_health=$((player_health + 3))
      player_knowledge=$((player_knowledge + 1))
      ;;
    *)
      narrate_warning "You skip today's practice, missing an opportunity to deepen your wisdom."
      ;;
  esac
  pause

  # Subtle random event each day
  random_event
}

############################
# RANDOM EVENTS (REPLAYABILITY)
############################
random_event() {
  # Some small chance of a random effect happening
  chance=$((RANDOM % 100))
  if [ $chance -lt 33 ]; then
    # Good event
    narrate_success "A helpful Hermetic adept crosses your path, offering encouragement and a small blessing."
    heal=$((RANDOM % 5 + 3))
    player_health=$((player_health + heal))
    player_knowledge=$((player_knowledge + 1))
    echo -e "${YELLOW}You gain $heal health and +1 knowledge. (Health: $player_health, Knowledge: $player_knowledge)${RESET}"
  elif [ $chance -lt 66 ]; then
    # Neutral event
    narrate "A quiet day, with no major events—yet subtle cosmic forces still shape your path."
  else
    # Challenging event
    narrate_danger "A desert sandstorm or moment of doubt disrupts your peace. You struggle to stay on course."
    dmg=$((RANDOM % 5 + 2))
    player_health=$((player_health - dmg))
    narrate_warning "You lose $dmg health. (Health: $player_health)"
    if [ $player_health -le 0 ]; then
      narrate_danger "Overcome by adversity, you collapse. Game Over."
      save_game
      exit 1
    fi
  fi
  pause
}

############################
# CHAPTERS: THE SEVEN PRINCIPLES
############################
# We will have 7 chapters, each focusing on a Hermetic principle:
#   1. Mentalism
#   2. Correspondence
#   3. Vibration
#   4. Polarity
#   5. Rhythm
#   6. Cause & Effect
#   7. Gender
#
# The user can approach them in sequential order. Each chapter has an
# immersive scenario, 3 choices, references the principle, and offers
# potential increases or decreases to knowledge/health.

chapter_mentalism() {
  clear
  echo -e "${BLUE}================================================================${RESET}"
  echo -e "${BLUE}   CHAPTER 1: The Principle of MENTALISM – 'All is Mind'         ${RESET}"
  echo -e "${BLUE}================================================================${RESET}"
  narrate "You arrive at a serene courtyard in the Temple complex. On a pedestal, an inscription reads:"
  narrate "\"The All is Mind; the Universe is Mental.\""
  narrate "A robed initiate beckons you closer, offering a test of your focus and understanding."
  echo
  narrate_warning "1) Attempt a telepathic connection with the initiate."
  narrate_warning "2) Quietly observe your own thoughts to find deeper truths."
  narrate_warning "3) Demand direct instruction from the initiate."
  echo -n "Choose (1,2,3): "

  choice=$(safe_read)
  case "$choice" in
    1)
      narrate "You close your eyes, imagining a mental link. The initiate’s calm presence meets yours in the silence."
      success=$((RANDOM % 100))
      if [ $success -lt 70 ]; then
        narrate_success "You sense each other's thoughts gently, confirming that all is indeed connected through Mind."
        player_knowledge=$((player_knowledge + 3))
      else
        narrate_warning "Your concentration wavers, and you can't quite establish a link this time."
      fi
      ;;
    2)
      narrate "Sitting down, you observe the chaos of your thoughts. Gradually, they settle into clarity."
      narrate_success "This insight reminds you that external reality reflects the patterns of Mind."
      player_knowledge=$((player_knowledge + 2))
      player_health=$((player_health + 2))
      ;;
    3)
      narrate_danger "Demanding knowledge disrupts the harmony. The initiate warns that aggression clouds the mental plane."
      dmg=$((RANDOM % 5 + 3))
      player_health=$((player_health - dmg))
      narrate_warning "You lose $dmg health due to stress and frustration."
      ;;
    *)
      narrate_warning "Uncertain how to proceed, you gain no immediate insight."
      ;;
  esac
  chapters_completed=$((chapters_completed + 1))
  pause
}

chapter_correspondence() {
  clear
  echo -e "${BLUE}================================================================${RESET}"
  echo -e "${BLUE} CHAPTER 2: The Principle of CORRESPONDENCE – 'As Above, So Below'${RESET}"
  echo -e "${BLUE}================================================================${RESET}"
  narrate "Deeper in the Temple, you encounter a mural depicting celestial bodies mirrored by earthly forms."
  narrate "\"As Above, so Below; as Below, so Above,\" reads the text."
  echo
  narrate_warning "1) Study the astronomical patterns carefully to decipher their earthly counterparts."
  narrate_warning "2) Speak with a traveling astronomer to share insights."
  narrate_warning "3) Write your own reflections on how cosmic forces manifest in daily life."
  echo -n "Choose (1,2,3): "

  choice=$(safe_read)
  case "$choice" in
    1)
      narrate "You trace the constellations, comparing them to the Nile's layout and the Temple architecture."
      narrate_success "You see how spiritual patterns shape material reality, awakening new levels of awareness."
      player_knowledge=$((player_knowledge + 3))
      ;;
    2)
      narrate "The astronomer offers charts and tells of star alignments. You share your own experiences."
      narrate_success "A synergy of minds emerges—'As Above, so Below' resonates deeply."
      player_knowledge=$((player_knowledge + 2))
      player_health=$((player_health + 1))
      ;;
    3)
      narrate "Sitting quietly, you write personal observations—how your internal states reflect outer circumstances."
      narrate_success "This journaling clarifies your path. You realize the same laws govern the macrocosm and microcosm."
      player_knowledge=$((player_knowledge + 2))
      ;;
    *)
      narrate_warning "You wander aimlessly, gleaning no further knowledge."
      ;;
  esac
  chapters_completed=$((chapters_completed + 1))
  pause
}

chapter_vibration() {
  clear
  echo -e "${BLUE}================================================================${RESET}"
  echo -e "${BLUE} CHAPTER 3: The Principle of VIBRATION – 'Nothing Rests; Everything Moves'${RESET}"
  echo -e "${BLUE}================================================================${RESET}"
  narrate "A hidden chamber hums with energy. You sense constant motion in the air and the walls themselves."
  narrate "\"Nothing rests; everything moves; everything vibrates,\" a priestess intones."
  echo
  narrate_warning "1) Meditate to feel the subtle vibrations of your own body and mind."
  narrate_warning "2) Experiment with a tuning fork to resonate with stones in the temple."
  narrate_warning "3) Request direct instruction from the priestess on raising your vibrational state."
  echo -n "Choose (1,2,3): "

  choice=$(safe_read)
  case "$choice" in
    1)
      narrate "You focus on your breathing, noticing tingling sensations. The entire cosmos vibrates in unity."
      player_knowledge=$((player_knowledge + 2))
      player_health=$((player_health + 2))
      narrate_success "You feel rejuvenated, more in tune with the life force around you."
      ;;
    2)
      narrate "Striking the tuning fork, you experiment with frequencies. Stones hum in harmony or discord."
      narrate "You realize how objects can align or repel based on vibrational resonance."
      player_knowledge=$((player_knowledge + 3))
      ;;
    3)
      narrate "The priestess shares advanced breathing exercises and chanting techniques to elevate your energy field."
      success=$((RANDOM % 100))
      if [ $success -lt 80 ]; then
        narrate_success "Your aura brightens; you feel heightened clarity and well-being."
        player_health=$((player_health + 4))
        player_knowledge=$((player_knowledge + 2))
      else
        narrate_warning "Your focus drifts, and the lesson remains incomplete."
      fi
      ;;
    *)
      narrate_warning "You hesitate, missing the lesson on cosmic vibration."
      ;;
  esac
  chapters_completed=$((chapters_completed + 1))
  pause
}

chapter_polarity() {
  clear
  echo -e "${BLUE}================================================================${RESET}"
  echo -e "${BLUE} CHAPTER 4: The Principle of POLARITY – 'Everything is Dual'       ${RESET}"
  echo -e "${BLUE}================================================================${RESET}"
  narrate "Antechamber paintings show opposite forces: fire and water, light and dark."
  narrate "\"Everything is Dual; everything has poles,\" the text proclaims."
  echo
  narrate_warning "1) Contemplate how joy and sorrow are but different degrees of the same emotion."
  narrate_warning "2) Try to reconcile a conflict between two temple acolytes over a lost relic."
  narrate_warning "3) Engage in a ritual merging fire and water to create steam, symbolizing unity."
  echo -n "Choose (1,2,3): "

  choice=$(safe_read)
  case "$choice" in
    1)
      narrate "Reflecting on your life, you see how extremes shift into each other, revealing unity beyond apparent differences."
      player_knowledge=$((player_knowledge + 2))
      ;;
    2)
      narrate "You listen to both acolytes, guiding them to realize they share a common purpose."
      success=$((RANDOM % 100))
      if [ $success -lt 70 ]; then
        narrate_success "They thank you, their hostility transformed into understanding. 'Polarities can converge,' they remark."
        player_knowledge=$((player_knowledge + 3))
      else
        narrate_warning "They remain stubborn, and you expend energy trying to calm them. Your health dips slightly."
        player_health=$((player_health - 3))
      fi
      ;;
    3)
      narrate "Combining fire and water in a small cauldron, you witness how opposites produce a transformative third state—steam."
      player_knowledge=$((player_knowledge + 2))
      player_health=$((player_health + 1))
      ;;
    *)
      narrate_warning "You remain distant, not fully embracing the teaching of polarity."
      ;;
  esac
  chapters_completed=$((chapters_completed + 1))
  pause
}

chapter_rhythm() {
  clear
  echo -e "${BLUE}================================================================${RESET}"
  echo -e "${BLUE} CHAPTER 5: The Principle of RHYTHM – 'Everything Flows, Out and In'${RESET}"
  echo -e "${BLUE}================================================================${RESET}"
  narrate "Entering a courtyard with a fountain, the water rises and falls in a steady cadence."
  narrate "\"Everything has its tides; all things rise and fall,\" reads an inscription."
  echo
  narrate_warning "1) Practice breathwork in time with the fountain's flow."
  narrate_warning "2) Observe the cyclical patterns of day and night through the temple's orrery."
  narrate_warning "3) Attempt to control the fountain's mechanism, seeking to break or alter the cycle."
  echo -n "Choose (1,2,3): "

  choice=$(safe_read)
  case "$choice" in
    1)
      narrate "Your breath matches the water's pulsing arc. Inhale, exhale—flow and ebb."
      narrate_success "A profound calm envelops you. You sense the universal rhythm in all things."
      player_health=$((player_health + 3))
      player_knowledge=$((player_knowledge + 2))
      ;;
    2)
      narrate "You watch mechanical spheres representing the sun and moon revolve. Patterns repeat in cosmic dance."
      player_knowledge=$((player_knowledge + 3))
      narrate_success "Understanding the cycles allows you to anticipate life's ebbs and flows more gracefully."
      ;;
    3)
      narrate_warning "Attempting to override the fountain’s flow is difficult. You partially disrupt it, splashing water everywhere!"
      dmg=$((RANDOM % 5 + 2))
      player_health=$((player_health - dmg))
      narrate_danger "You're drenched and slightly bruised. You lose $dmg health."
      ;;
    *)
      narrate_warning "You hesitate, missing the lesson of life's rhythms."
      ;;
  esac
  chapters_completed=$((chapters_completed + 1))
  pause
}

chapter_cause_effect() {
  clear
  echo -e "${BLUE}================================================================${RESET}"
  echo -e "${BLUE} CHAPTER 6: The Principle of CAUSE & EFFECT – 'Every Cause has Its Effect'${RESET}"
  echo -e "${BLUE}================================================================${RESET}"
  narrate "In a hall lined with statues of past sages, a great scroll proclaims: 'Every cause has its effect; every effect has its cause.'"
  echo
  narrate_warning "1) Investigate the temple’s records of past events to see how small actions led to great consequences."
  narrate_warning "2) Perform a mini-experiment: dropping stones into a pool to see ripples spread."
  narrate_warning "3) Speak with an elder about how personal responsibility aligns with cosmic order."
  echo -n "Choose (1,2,3): "

  choice=$(safe_read)
  case "$choice" in
    1)
      narrate "You pore over ancient accounts. From minor seeds grew mighty dynasties; from single choices came revolutions."
      narrate_success "Your sense of responsibility deepens. You see how each choice can shape destinies."
      player_knowledge=$((player_knowledge + 3))
      ;;
    2)
      narrate "Each stone’s impact produces concentric ripples that eventually reach the pool's edge."
      narrate "You reflect on how intentions set forth consequences in life's vast waters."
      player_knowledge=$((player_knowledge + 2))
      ;;
    3)
      narrate "An elder explains that free will coexists with universal laws. Conscious choices lead to mindful causes."
      success=$((RANDOM % 100))
      if [ $success -lt 80 ]; then
        narrate_success "Enlightened by these insights, you vow to act with greater awareness."
        player_knowledge=$((player_knowledge + 3))
      else
        narrate_warning "Your mind drifts, missing key points of the elder's wisdom."
      fi
      ;;
    *)
      narrate_warning "You linger in confusion, failing to grasp the chain of cause and effect."
      ;;
  esac
  chapters_completed=$((chapters_completed + 1))
  pause
}

chapter_gender() {
  clear
  echo -e "${BLUE}================================================================${RESET}"
  echo -e "${BLUE} CHAPTER 7: The Principle of GENDER – 'Gender is in Everything'   ${RESET}"
  echo -e "${BLUE}================================================================${RESET}"
  narrate "A final sanctum displays symbols of complementary forces—masculine and feminine essences in all creation."
  narrate "\"Gender is in everything; everything has its Masculine and Feminine Principles,\" a scroll declares."
  echo
  narrate_warning "1) Attend a ritual celebrating the union of these complementary energies in nature."
  narrate_warning "2) Speak with temple artisans on how they balance design elements (yin and yang, so to speak)."
  narrate_warning "3) Reflect privately on how these polarities manifest within your psyche."
  echo -n "Choose (1,2,3): "

  choice=$(safe_read)
  case "$choice" in
    1)
      narrate "The ritual illustrates creation emerging from the interplay of active and receptive principles."
      narrate_success "You sense deeper harmony in the dance of life. Your knowledge expands significantly."
      player_knowledge=$((player_knowledge + 3))
      ;;
    2)
      narrate "Sculptors and painters show how each work combines strong, assertive lines with flowing, nurturing curves."
      narrate_success "You realize creation thrives on balanced synergy. This shapes your understanding of all relationships."
      player_knowledge=$((player_knowledge + 2))
      ;;
    3)
      narrate "Internally, you identify aspects of your own nature: the drive to act and the capacity to receive."
      narrate_success "Recognizing both energies fosters wholeness. You feel more balanced."
      player_knowledge=$((player_knowledge + 2))
      player_health=$((player_health + 2))
      ;;
    *)
      narrate_warning "You remain unsure, missing the essential lesson of the final principle."
      ;;
  esac
  chapters_completed=$((chapters_completed + 1))
  pause
}

############################
# FINALE & REPLAY
############################
finale() {
  clear
  echo -e "${GREEN}=============================================================${RESET}"
  echo -e "${GREEN}            T H E   E M E R A L D   T A B L E T               ${RESET}"
  echo -e "${GREEN}=============================================================${RESET}"

  if [ $chapters_completed -lt 7 ]; then
    narrate_warning "You have not yet explored all seven Hermetic Principles. There is still more to learn."
    narrate "Return another day to deepen your knowledge."
  else
    # All 7 principles completed
    narrate_magenta "You stand before the final inscriptions upon the Emerald Tablet. The synergy of all principles resonates within you."
    if [ $player_knowledge -lt 10 ]; then
      narrate_warning "Though you traversed each principle, your comprehension remains at an early stage."
      narrate "You sense that repeated study and practice will reveal ever deeper layers of truth."
    elif [ $player_knowledge -lt 20 ]; then
      narrate_success "Having integrated each lesson to a fair degree, your mind and spirit are on the path of mastery."
      narrate "You realize, however, that the journey of Hermetic wisdom is endless."
    else
      narrate_success "Your immersion in the teachings has awakened a profound transformation within. A luminous clarity envelops you."
      narrate "In future journeys, you will serve as a guide to others seeking the sacred knowledge."
    fi
  fi

  echo
  narrate "As you conclude this session, you feel called to continue daily practice to refine your insights."
  narrate_warning "May your path be illuminated by the wisdom of the Emerald Tablet."
  pause

  # Prepare for next "day"
  player_day=$((player_day + 1))
  save_game

  echo -e "${YELLOW}Thank you for playing! You can return anytime to discover new details, daily practices, and random events.${RESET}"
  echo -e "${YELLOW}Your progress (health: $player_health, knowledge: $player_knowledge, day: $player_day) has been recorded.${RESET}"
  echo
  exit 0
}

############################
# MAIN GAME FLOW
############################
intro_sequence

# Offer daily practice if returning
daily_practice

# Next, let the user choose which principle/chapter they want to explore,
# or revisit daily practice, or skip. They can only do so many in one session,
# or as many as they want—your design choice.
# We'll show only chapters they haven't completed yet.

while true; do
  clear
  echo -e "${GREEN}=======================${RESET}"
  echo -e "${GREEN}   HERMETIC INDEX      ${RESET}"
  echo -e "${GREEN}=======================${RESET}"
  echo -e "${MAGENTA}Choose a principle/chapter to explore or type (q) to quit:${RESET}"
  echo

  if [ $chapters_completed -lt 7 ]; then
    [ $chapters_completed -lt 1 ] && echo "1) Mentalism"
    [ $chapters_completed -lt 2 ] && echo "2) Correspondence"
    [ $chapters_completed -lt 3 ] && echo "3) Vibration"
    [ $chapters_completed -lt 4 ] && echo "4) Polarity"
    [ $chapters_completed -lt 5 ] && echo "5) Rhythm"
    [ $chapters_completed -lt 6 ] && echo "6) Cause & Effect"
    [ $chapters_completed -lt 7 ] && echo "7) Gender"
    echo "8) Proceed to the Emerald Tablet (Final)"
  else
    echo "(All 7 principles explored!)"
    echo "8) Proceed to the Emerald Tablet (Final)"
  fi

  echo "9) Review Daily Practice again (optional)"

  echo -n "Make a selection (1-9): "
  choice=$(safe_read)
  case "$choice" in
    1) if [ $chapters_completed -lt 1 ]; then chapter_mentalism; else narrate_warning "You have already studied Mentalism." ; pause; fi ;;
    2) if [ $chapters_completed -lt 2 ]; then chapter_correspondence; else narrate_warning "You have already studied Correspondence." ; pause; fi ;;
    3) if [ $chapters_completed -lt 3 ]; then chapter_vibration; else narrate_warning "You have already studied Vibration." ; pause; fi ;;
    4) if [ $chapters_completed -lt 4 ]; then chapter_polarity; else narrate_warning "You have already studied Polarity." ; pause; fi ;;
    5) if [ $chapters_completed -lt 5 ]; then chapter_rhythm; else narrate_warning "You have already studied Rhythm." ; pause; fi ;;
    6) if [ $chapters_completed -lt 6 ]; then chapter_cause_effect; else narrate_warning "You have already studied Cause & Effect." ; pause; fi ;;
    7) if [ $chapters_completed -lt 7 ]; then chapter_gender; else narrate_warning "You have already studied Gender." ; pause; fi ;;
    8) finale ;;
    9) daily_practice ;;
    *)
      narrate_warning "Invalid choice. Try again."
      pause
      ;;
  esac
done
