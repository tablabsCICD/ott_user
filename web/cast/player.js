/**
 * FilmyTell Cast Receiver Player Controller
 * Handles watermarks, brand loading overlays, and playback lifecycle.
 */

class FilmyTellPlayerController {
  constructor() {
    this.watermarkTimer = null;
    this.watermarkElement = document.getElementById('custom-watermark-container');
    this.watermarkTextElement = document.getElementById('watermark-text');
    this.loaderElement = document.getElementById('custom-loader');
  }

  showLoader(show) {
    if (this.loaderElement) {
      this.loaderElement.style.display = show ? 'flex' : 'none';
    }
  }

  setupWatermark(watermarkText) {
    if (!watermarkText || !this.watermarkElement || !this.watermarkTextElement) return;

    this.watermarkTextElement.textContent = watermarkText;
    this.watermarkElement.style.display = 'block';

    // Position randomly across corners periodically to prevent screen burn-in
    if (this.watermarkTimer) clearInterval(this.watermarkTimer);
    this.rotateWatermarkPosition();
    this.watermarkTimer = setInterval(() => {
      this.rotateWatermarkPosition();
    }, 45000);
  }

  rotateWatermarkPosition() {
    if (!this.watermarkElement) return;
    const positions = [
      { top: '40px', right: '60px', bottom: 'auto', left: 'auto' },
      { top: '40px', left: '60px', bottom: 'auto', right: 'auto' },
      { bottom: '60px', right: '60px', top: 'auto', left: 'auto' },
      { bottom: '60px', left: '60px', top: 'auto', right: 'auto' }
    ];
    const nextPos = positions[Math.floor(Math.random() * positions.length)];
    Object.assign(this.watermarkElement.style, nextPos);
  }

  clearWatermark() {
    if (this.watermarkTimer) {
      clearInterval(this.watermarkTimer);
      this.watermarkTimer = null;
    }
    if (this.watermarkElement) {
      this.watermarkElement.style.display = 'none';
    }
  }
}

window.filmytellPlayer = new FilmyTellPlayerController();
