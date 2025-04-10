// app/javascript/packs/heidi_widget.js

// Function to initialize the Heidi widget with the provided token
function initializeHeidiWidget(token) {
    if (typeof HeidiWidget !== 'undefined' && HeidiWidget.init) {
      HeidiWidget.init({
        token: token,
        // Add other configuration options here
      });
    } else {
      console.error('HeidiWidget is not defined.');
    }
  }
  
  // Make this function available globally
  window.initializeHeidiWidget = initializeHeidiWidget;
  