{{flutter_js}}
{{flutter_build_config}}

(async () => {
  const isLocalhost =
      window.location.hostname === 'localhost' ||
      window.location.hostname === '127.0.0.1';

  if (isLocalhost && 'serviceWorker' in navigator) {
    const registrations = await navigator.serviceWorker.getRegistrations();
    await Promise.all(registrations.map((registration) => registration.unregister()));
  }

  if (isLocalhost) {
    const cacheVersion = Date.now();
    for (const build of _flutter.buildConfig.builds) {
      if (build.mainJsPath) {
        build.mainJsPath = `${build.mainJsPath}?v=${cacheVersion}`;
      }
    }
  }

  await _flutter.loader.load();
})();
