// ==UserScript==
// @name        DeepL speechSynthesis fix
// @match       https://www.deepl.com/*
// @run-at      document-start
// @grant       none
// ==/UserScript==

const s = document.createElement('script');
s.textContent = `
  if (!window.speechSynthesis) {
    window.speechSynthesis = { getVoices: () => [], speak: () => {}, cancel: () => {}, pause: () => {}, resume: () => {} };
  }
`;
(document.head || document.documentElement).prepend(s);
