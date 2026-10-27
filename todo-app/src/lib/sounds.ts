import { createAudioPlayer, setAudioModeAsync, type AudioPlayer } from 'expo-audio';
import type { SoundId } from '../theme/themes';

// File creati da scripts/make-sounds.mjs
const SOURCES: Record<SoundId, number> = {
  soft: require('../../assets/sounds/soft.wav'),
  arcade: require('../../assets/sounds/arcade.wav'),
  atelier: require('../../assets/sounds/atelier.wav'),
  studio: require('../../assets/sounds/studio.wav'),
};

const players: Partial<Record<SoundId, AudioPlayer>> = {};
let modeReady = false;

// Suona il suono di un tema. Se qualcosa va storto non deve mai rompere l'app.
export function playSound(id: SoundId) {
  try {
    if (!modeReady) {
      modeReady = true;
      // non interrompe la musica che sta già suonando e rispetta il tasto silenzioso
      void setAudioModeAsync({ playsInSilentMode: false, interruptionMode: 'mixWithOthers' });
    }
    const player = players[id] ?? (players[id] = createAudioPlayer(SOURCES[id]));
    void player.seekTo(0);
    player.play();
  } catch {
    // niente suono, pazienza
  }
}
