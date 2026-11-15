(() => {
  const rendered = new WeakSet();
  let initialized = false;

  function renderButton() {
    const container = document.getElementById('google-sign-in-button');
    const googleId = window.google?.accounts?.id;
    const clientId = container?.dataset.googleClientId;
    if (!container || !googleId || !clientId || rendered.has(container)) return;

    if (!initialized) {
      googleId.initialize({
        client_id: clientId,
        callback: (response) => {
          const receiver = document.getElementById('google-id-token');
          if (!response.credential || !receiver) return;
          receiver.value = response.credential;
          receiver.dispatchEvent(new Event('input', { bubbles: true }));
          receiver.value = '';
        },
      });
      initialized = true;
    }

    const width = Math.min(
      400,
      Math.max(200, Math.floor(container.getBoundingClientRect().width)),
    );
    googleId.renderButton(container, {
      theme: 'outline',
      size: 'large',
      text: 'continue_with',
      shape: 'pill',
      width,
    });
    rendered.add(container);
  }

  new MutationObserver(renderButton).observe(document.documentElement, {
    childList: true,
    subtree: true,
  });
  window.addEventListener('load', renderButton);
})();
