/* ENTRYPOINT_EXTENTION_MARKER */
(function() {
var _currentDirectory = (function () {
  var _url;
  var lines = new Error().stack.split('\n');
  function lookupUrl() {
    if (lines.length > 2) {
      var match = lines[1].match(/^\s+at (.+):\d+:\d+$/);
      // Chrome.
      if (match) return match[1];
      // Chrome nested eval case.
      match = lines[1].match(/^\s+at eval [(](.+):\d+:\d+[)]$/);
      if (match) return match[1];
      // Edge.
      match = lines[1].match(/^\s+at.+\((.+):\d+:\d+\)$/);
      if (match) return match[1];
      // Firefox.
      match = lines[0].match(/[<][@](.+):\d+:\d+$/)
      if (match) return match[1];
    }
    // Safari.
    return lines[0].match(/[@](.+):\d+:\d+$/)[1];
  }
  _url = lookupUrl();
  var lastSlash = _url.lastIndexOf('/');
  if (lastSlash == -1) return _url;
  var currentDirectory = _url.substring(0, lastSlash + 1);
  return currentDirectory;
})();

var baseUrl = (function () {
  // Attempt to detect --precompiled mode for tests, and set the base url
  // appropriately, otherwise set it to '/'.
  var pathParts = location.pathname.split("/");
  if (pathParts[0] == "") {
    pathParts.shift();
  }
  if (pathParts.length > 1 && pathParts[1] == "test") {
    return "/" + pathParts.slice(0, 2).join("/") + "/";
  }
  // Attempt to detect base url using <base href> html tag
  // base href should start and end with "/"
  if (typeof document !== 'undefined') {
    var el = document.getElementsByTagName('base');
    if (el && el[0] && el[0].getAttribute("href") && el[0].getAttribute
    ("href").startsWith("/") && el[0].getAttribute("href").endsWith("/")){
      return el[0].getAttribute("href");
    }
  }
  // return default value
  return "/";
}());

let modulePaths = {
 "dart_sdk": "packages/build_web_compilers/src/dev_compiler/dart_sdk",
 "packages/collection/collection": "packages/collection/collection.ddc",
 "packages/collection/src/algorithms": "packages/collection/src/algorithms.ddc",
 "packages/collection/src/canonicalized_map": "packages/collection/src/canonicalized_map.ddc",
 "packages/collection/src/comparators": "packages/collection/src/comparators.ddc",
 "packages/collection/src/iterable_zip": "packages/collection/src/iterable_zip.ddc",
 "packages/collection/src/priority_queue": "packages/collection/src/priority_queue.ddc",
 "packages/collection/src/utils": "packages/collection/src/utils.ddc",
 "packages/crypto/crypto": "packages/crypto/crypto.ddc",
 "packages/eduma_web/app": "packages/eduma_web/app.ddc",
 "packages/eduma_web/core/data/eduma_memory_cache": "packages/eduma_web/core/data/eduma_memory_cache.ddc",
 "packages/eduma_web/core/data/json_envelope": "packages/eduma_web/core/data/json_envelope.ddc",
 "packages/eduma_web/core/presentation/desktop_scaffolds": "packages/eduma_web/core/presentation/desktop_scaffolds.ddc",
 "packages/eduma_web/core/presentation/eduma_cover_fallback": "packages/eduma_web/core/presentation/eduma_cover_fallback.ddc",
 "packages/eduma_web/core/presentation/eduma_icons": "packages/eduma_web/core/presentation/eduma_icons.ddc",
 "packages/eduma_web/core/presentation/eduma_link": "packages/eduma_web/core/presentation/eduma_link.ddc",
 "packages/eduma_web/core/presentation/eduma_rich_text": "packages/eduma_web/core/presentation/eduma_rich_text.ddc",
 "packages/eduma_web/core/presentation/see_all_bottom_bar": "packages/eduma_web/core/presentation/see_all_bottom_bar.ddc",
 "packages/eduma_web/core/presentation/theme_controller": "packages/eduma_web/core/presentation/theme_controller.ddc",
 "packages/eduma_web/core/utils/date_formatters": "packages/eduma_web/core/utils/date_formatters.ddc",
 "packages/eduma_web/features/ai/data/ai_history_api": "packages/eduma_web/features/ai/data/ai_history_api.ddc",
 "packages/eduma_web/features/ai/data/ai_history_models": "packages/eduma_web/features/ai/data/ai_history_models.ddc",
 "packages/eduma_web/features/ai/presentation/pages/assistant_history_page": "packages/eduma_web/features/ai/presentation/pages/assistant_history_page.ddc",
 "packages/eduma_web/features/auth/logic/auth_actions": "packages/eduma_web/features/auth/logic/auth_actions.ddc",
 "packages/eduma_web/features/auth/logic/auth_link_logic": "packages/eduma_web/features/auth/logic/auth_link_logic.ddc",
 "packages/eduma_web/features/auth/logic/sign_up_logic": "packages/eduma_web/features/auth/logic/sign_up_logic.ddc",
 "packages/eduma_web/features/auth/presentation/pages/forgot_password": "packages/eduma_web/features/auth/presentation/pages/forgot_password.ddc",
 "packages/eduma_web/features/auth/presentation/pages/sign_in": "packages/eduma_web/features/auth/presentation/pages/sign_in.ddc",
 "packages/eduma_web/features/auth/presentation/pages/sign_up": "packages/eduma_web/features/auth/presentation/pages/sign_up.ddc",
 "packages/eduma_web/features/auth/presentation/pages/verify_email": "packages/eduma_web/features/auth/presentation/pages/verify_email.ddc",
 "packages/eduma_web/features/auth/presentation/widgets/auth_frame": "packages/eduma_web/features/auth/presentation/widgets/auth_frame.ddc",
 "packages/eduma_web/features/auth/presentation/widgets/sign_up_bars": "packages/eduma_web/features/auth/presentation/widgets/sign_up_bars.ddc",
 "packages/eduma_web/features/auth/presentation/widgets/sign_up_photo_step": "packages/eduma_web/features/auth/presentation/widgets/sign_up_photo_step.ddc",
 "packages/eduma_web/features/auth/presentation/widgets/sign_up_steps": "packages/eduma_web/features/auth/presentation/widgets/sign_up_steps.ddc",
 "packages/eduma_web/features/calendar/data/calendar_api": "packages/eduma_web/features/calendar/data/calendar_api.ddc",
 "packages/eduma_web/features/calendar/data/calendar_models": "packages/eduma_web/features/calendar/data/calendar_models.ddc",
 "packages/eduma_web/features/calendar/logic/calendar_actions": "packages/eduma_web/features/calendar/logic/calendar_actions.ddc",
 "packages/eduma_web/features/calendar/presentation/pages/calendar_page": "packages/eduma_web/features/calendar/presentation/pages/calendar_page.ddc",
 "packages/eduma_web/features/calendar/presentation/widgets/calendar_create_dialog": "packages/eduma_web/features/calendar/presentation/widgets/calendar_create_dialog.ddc",
 "packages/eduma_web/features/calendar/presentation/widgets/calendar_day_agenda": "packages/eduma_web/features/calendar/presentation/widgets/calendar_day_agenda.ddc",
 "packages/eduma_web/features/calendar/presentation/widgets/calendar_mini_month": "packages/eduma_web/features/calendar/presentation/widgets/calendar_mini_month.ddc",
 "packages/eduma_web/features/calendar/presentation/widgets/calendar_modals": "packages/eduma_web/features/calendar/presentation/widgets/calendar_modals.ddc",
 "packages/eduma_web/features/library/data/library_api": "packages/eduma_web/features/library/data/library_api.ddc",
 "packages/eduma_web/features/library/data/library_models": "packages/eduma_web/features/library/data/library_models.ddc",
 "packages/eduma_web/features/library/logic/library_actions": "packages/eduma_web/features/library/logic/library_actions.ddc",
 "packages/eduma_web/features/library/presentation/pages/library_page": "packages/eduma_web/features/library/presentation/pages/library_page.ddc",
 "packages/eduma_web/features/library/presentation/widgets/library_dialogs": "packages/eduma_web/features/library/presentation/widgets/library_dialogs.ddc",
 "packages/eduma_web/features/library/presentation/widgets/library_document_card": "packages/eduma_web/features/library/presentation/widgets/library_document_card.ddc",
 "packages/eduma_web/features/library/presentation/widgets/library_reader_dialog": "packages/eduma_web/features/library/presentation/widgets/library_reader_dialog.ddc",
 "packages/eduma_web/features/library/presentation/widgets/library_shelves_section": "packages/eduma_web/features/library/presentation/widgets/library_shelves_section.ddc",
 "packages/eduma_web/features/main/data/main_api": "packages/eduma_web/features/main/data/main_api.ddc",
 "packages/eduma_web/features/main/data/main_canvas": "packages/eduma_web/features/main/data/main_canvas.ddc",
 "packages/eduma_web/features/main/data/main_preference_codec": "packages/eduma_web/features/main/data/main_preference_codec.ddc",
 "packages/eduma_web/features/main/data/main_preferences": "packages/eduma_web/features/main/data/main_preferences.ddc",
 "packages/eduma_web/features/main/data/main_space": "packages/eduma_web/features/main/data/main_space.ddc",
 "packages/eduma_web/features/main/data/main_space_mutations": "packages/eduma_web/features/main/data/main_space_mutations.ddc",
 "packages/eduma_web/features/main/logic/main_actions": "packages/eduma_web/features/main/logic/main_actions.ddc",
 "packages/eduma_web/features/main/logic/main_space_query": "packages/eduma_web/features/main/logic/main_space_query.ddc",
 "packages/eduma_web/features/main/logic/space_invite_link": "packages/eduma_web/features/main/logic/space_invite_link.ddc",
 "packages/eduma_web/features/main/presentation/pages/main_home": "packages/eduma_web/features/main/presentation/pages/main_home.ddc",
 "packages/eduma_web/features/main/presentation/pages/recent_canvases_see_all_page": "packages/eduma_web/features/main/presentation/pages/recent_canvases_see_all_page.ddc",
 "packages/eduma_web/features/main/presentation/pages/spaces_see_all_page": "packages/eduma_web/features/main/presentation/pages/spaces_see_all_page.ddc",
 "packages/eduma_web/features/main/presentation/widgets/app_tab_shell": "packages/eduma_web/features/main/presentation/widgets/app_tab_shell.ddc",
 "packages/eduma_web/features/main/presentation/widgets/calendar_agenda_panel": "packages/eduma_web/features/main/presentation/widgets/calendar_agenda_panel.ddc",
 "packages/eduma_web/features/main/presentation/widgets/main_home_create_space_dialog": "packages/eduma_web/features/main/presentation/widgets/main_home_create_space_dialog.ddc",
 "packages/eduma_web/features/main/presentation/widgets/main_home_helpers": "packages/eduma_web/features/main/presentation/widgets/main_home_helpers.ddc",
 "packages/eduma_web/features/main/presentation/widgets/main_home_highlights": "packages/eduma_web/features/main/presentation/widgets/main_home_highlights.ddc",
 "packages/eduma_web/features/main/presentation/widgets/main_home_icons": "packages/eduma_web/features/main/presentation/widgets/main_home_icons.ddc",
 "packages/eduma_web/features/main/presentation/widgets/main_home_join_space_dialog": "packages/eduma_web/features/main/presentation/widgets/main_home_join_space_dialog.ddc",
 "packages/eduma_web/features/main/presentation/widgets/main_home_navigation": "packages/eduma_web/features/main/presentation/widgets/main_home_navigation.ddc",
 "packages/eduma_web/features/main/presentation/widgets/main_home_notices": "packages/eduma_web/features/main/presentation/widgets/main_home_notices.ddc",
 "packages/eduma_web/features/main/presentation/widgets/main_home_search_bar": "packages/eduma_web/features/main/presentation/widgets/main_home_search_bar.ddc",
 "packages/eduma_web/features/main/presentation/widgets/main_home_space_context_menu": "packages/eduma_web/features/main/presentation/widgets/main_home_space_context_menu.ddc",
 "packages/eduma_web/features/main/presentation/widgets/main_home_spaces_section": "packages/eduma_web/features/main/presentation/widgets/main_home_spaces_section.ddc",
 "packages/eduma_web/features/main/presentation/widgets/web_dialog_helper": "packages/eduma_web/features/main/presentation/widgets/web_dialog_helper.ddc",
 "packages/eduma_web/features/notifications/data/notifications_api": "packages/eduma_web/features/notifications/data/notifications_api.ddc",
 "packages/eduma_web/features/notifications/data/notifications_models": "packages/eduma_web/features/notifications/data/notifications_models.ddc",
 "packages/eduma_web/features/notifications/logic/notifications_actions": "packages/eduma_web/features/notifications/logic/notifications_actions.ddc",
 "packages/eduma_web/features/notifications/presentation/pages/notifications_page": "packages/eduma_web/features/notifications/presentation/pages/notifications_page.ddc",
 "packages/eduma_web/features/profile/data/profile_api": "packages/eduma_web/features/profile/data/profile_api.ddc",
 "packages/eduma_web/features/profile/data/profile_models": "packages/eduma_web/features/profile/data/profile_models.ddc",
 "packages/eduma_web/features/profile/logic/profile_actions": "packages/eduma_web/features/profile/logic/profile_actions.ddc",
 "packages/eduma_web/features/profile/presentation/pages/profile_page": "packages/eduma_web/features/profile/presentation/pages/profile_page.ddc",
 "packages/eduma_web/features/profile/presentation/widgets/profile_account_dialogs": "packages/eduma_web/features/profile/presentation/widgets/profile_account_dialogs.ddc",
 "packages/eduma_web/features/profile/presentation/widgets/profile_edit_dialog": "packages/eduma_web/features/profile/presentation/widgets/profile_edit_dialog.ddc",
 "packages/eduma_web/features/profile/presentation/widgets/profile_hero_widgets": "packages/eduma_web/features/profile/presentation/widgets/profile_hero_widgets.ddc",
 "packages/eduma_web/features/profile/presentation/widgets/profile_password_dialog": "packages/eduma_web/features/profile/presentation/widgets/profile_password_dialog.ddc",
 "packages/eduma_web/features/profile/presentation/widgets/profile_settings_groups": "packages/eduma_web/features/profile/presentation/widgets/profile_settings_groups.ddc",
 "packages/eduma_web/features/space/data/space_detail_models": "packages/eduma_web/features/space/data/space_detail_models.ddc",
 "packages/eduma_web/features/space/data/space_page_content_models": "packages/eduma_web/features/space/data/space_page_content_models.ddc",
 "packages/eduma_web/features/space/logic/space_detail_actions": "packages/eduma_web/features/space/logic/space_detail_actions.ddc",
 "packages/eduma_web/features/space/presentation/pages/space_detail_page": "packages/eduma_web/features/space/presentation/pages/space_detail_page.ddc",
 "packages/eduma_web/features/space/presentation/pages/space_page_viewer_page": "packages/eduma_web/features/space/presentation/pages/space_page_viewer_page.ddc",
 "packages/eduma_web/features/space/presentation/widgets/space_detail_dialogs": "packages/eduma_web/features/space/presentation/widgets/space_detail_dialogs.ddc",
 "packages/eduma_web/features/space/presentation/widgets/space_detail_hero": "packages/eduma_web/features/space/presentation/widgets/space_detail_hero.ddc",
 "packages/eduma_web/features/space/presentation/widgets/space_detail_members_tab": "packages/eduma_web/features/space/presentation/widgets/space_detail_members_tab.ddc",
 "packages/eduma_web/features/space/presentation/widgets/space_detail_pages_tab": "packages/eduma_web/features/space/presentation/widgets/space_detail_pages_tab.ddc",
 "packages/eduma_web/features/space/presentation/widgets/space_detail_tabs_content": "packages/eduma_web/features/space/presentation/widgets/space_detail_tabs_content.ddc",
 "packages/eduma_web/features/streak/data/streak_api": "packages/eduma_web/features/streak/data/streak_api.ddc",
 "packages/eduma_web/features/streak/data/streak_models": "packages/eduma_web/features/streak/data/streak_models.ddc",
 "packages/eduma_web/features/streak/presentation/pages/streak_page": "packages/eduma_web/features/streak/presentation/pages/streak_page.ddc",
 "packages/eduma_web/features/streak/presentation/widgets/streak_sections": "packages/eduma_web/features/streak/presentation/widgets/streak_sections.ddc",
 "packages/eduma_web/main.client": "packages/eduma_web/main.client.ddc",
 "packages/hive_ce/hive": "packages/hive_ce/hive.ddc",
 "packages/http/browser_client": "packages/http/browser_client.ddc",
 "packages/http/http": "packages/http/http.ddc",
 "packages/http/src/boundary_characters": "packages/http/src/boundary_characters.ddc",
 "packages/http_parser/http_parser": "packages/http_parser/http_parser.ddc",
 "packages/jaspr/client": "packages/jaspr/client.ddc",
 "packages/jaspr/src/client/utils": "packages/jaspr/src/client/utils.ddc",
 "packages/jaspr_router/jaspr_router": "packages/jaspr_router/jaspr_router.ddc",
 "packages/json_annotation/json_annotation": "packages/json_annotation/json_annotation.ddc",
 "packages/meta/meta": "packages/meta/meta.ddc",
 "packages/meta/meta_meta": "packages/meta/meta_meta.ddc",
 "packages/path/path": "packages/path/path.ddc",
 "packages/source_span/source_span": "packages/source_span/source_span.ddc",
 "packages/string_scanner/src/charcode": "packages/string_scanner/src/charcode.ddc",
 "packages/term_glyph/src/generated/ascii_glyph_set": "packages/term_glyph/src/generated/ascii_glyph_set.ddc",
 "packages/typed_data/src/typed_buffer": "packages/typed_data/src/typed_buffer.ddc",
 "packages/typed_data/src/typed_queue": "packages/typed_data/src/typed_queue.ddc",
 "packages/typed_data/typed_buffers": "packages/typed_data/typed_buffers.ddc",
 "packages/universal_web/js_interop": "packages/universal_web/js_interop.ddc",
 "packages/universal_web/web": "packages/universal_web/web.ddc",
 "packages/web/src/dom": "packages/web/src/dom.ddc",
 "packages/web/web": "packages/web/web.ddc",
 "web/main.client": "main.client.ddc"
};
if(!window.$dartLoader) {
   window.$dartLoader = {
     appDigests: _currentDirectory + 'main.client.digests',
     moduleIdToUrl: new Map(),
     urlToModuleId: new Map(),
     rootDirectories: new Array(),
     // Used in package:build_runner/src/server/build_updates_client/hot_reload_client.dart
     moduleParentsGraph: new Map(),
     moduleLoadingErrorCallbacks: new Map(),
     forceLoadModule: function (moduleName, callback, onError) {
       // dartdevc only strips the final extension when adding modules to source
       // maps, so we need to do the same.
       if (moduleName.endsWith('.ddc')) {
         moduleName = moduleName.substring(0, moduleName.length - 4);
       }
       if (typeof onError != 'undefined') {
         var errorCallbacks = $dartLoader.moduleLoadingErrorCallbacks;
         if (!errorCallbacks.has(moduleName)) {
           errorCallbacks.set(moduleName, new Set());
         }
         errorCallbacks.get(moduleName).add(onError);
       }
       requirejs.undef(moduleName);
       requirejs([moduleName], function() {
         if (typeof onError != 'undefined') {
           errorCallbacks.get(moduleName).delete(onError);
         }
         if (typeof callback != 'undefined') {
           callback();
         }
       });
     },
     getModuleLibraries: null, // set up by _initializeTools
   };
}
let customModulePaths = {};
window.$dartLoader.rootDirectories.push(window.location.origin + baseUrl);
for (let moduleName of Object.getOwnPropertyNames(modulePaths)) {
  let modulePath = modulePaths[moduleName];
  if (modulePath != moduleName) {
    customModulePaths[moduleName] = modulePath;
  }
  var src = window.location.origin + '/' + modulePath + '.js';
  if (window.$dartLoader.moduleIdToUrl.has(moduleName)) {
    continue;
  }
  $dartLoader.moduleIdToUrl.set(moduleName, src);
  $dartLoader.urlToModuleId.set(src, moduleName);
}
// Whenever we fail to load a JS module, try to request the corresponding
// `.errors` file, and log it to the console.
(function() {
  var oldOnError = requirejs.onError;
  requirejs.onError = function(e) {
    if (e.requireModules) {
      if (e.message) {
        // If error occurred on loading dependencies, we need to invalidate ancessor too.
        var ancesor = e.message.match(/needed by: (.*)/);
        if (ancesor) {
          e.requireModules.push(ancesor[1]);
        }
      }
      for (const module of e.requireModules) {
        var errorCallbacks = $dartLoader.moduleLoadingErrorCallbacks.get(module);
        if (errorCallbacks) {
          for (const callback of errorCallbacks) callback(e);
          errorCallbacks.clear();
        }
      }
    }
    if (e.originalError && e.originalError.srcElement) {
      var xhr = new XMLHttpRequest();
      xhr.onreadystatechange = function() {
        if (this.readyState == 4) {
          var message;
          if (this.status == 200) {
            message = this.responseText;
          } else {
            message = "Unknown error loading " + e.originalError.srcElement.src;
          }
          console.error(message);
          var errorEvent = new CustomEvent(
            'dartLoadException', { detail: message });
          window.dispatchEvent(errorEvent);
        }
      };
      xhr.open("GET", e.originalError.srcElement.src + ".errors", true);
      xhr.send();
    }
    // Also handle errors the normal way.
    if (oldOnError) oldOnError(e);
  };
}());

var baseUrl = (function () {
  // Attempt to detect --precompiled mode for tests, and set the base url
  // appropriately, otherwise set it to '/'.
  var pathParts = location.pathname.split("/");
  if (pathParts[0] == "") {
    pathParts.shift();
  }
  if (pathParts.length > 1 && pathParts[1] == "test") {
    return "/" + pathParts.slice(0, 2).join("/") + "/";
  }
  // Attempt to detect base url using <base href> html tag
  // base href should start and end with "/"
  if (typeof document !== 'undefined') {
    var el = document.getElementsByTagName('base');
    if (el && el[0] && el[0].getAttribute("href") && el[0].getAttribute
    ("href").startsWith("/") && el[0].getAttribute("href").endsWith("/")){
      return el[0].getAttribute("href");
    }
  }
  // return default value
  return "/";
}());
;

require.config({
    baseUrl: baseUrl,
    waitSeconds: 0,
    paths: customModulePaths
});

const modulesGraph = new Map();
function getRegisteredModuleName(moduleMap) {
  if ($dartLoader.moduleIdToUrl.has(moduleMap.name + '.ddc')) {
    return moduleMap.name + '.ddc';
  }
  return moduleMap.name;
}
requirejs.onResourceLoad = function (context, map, depArray) {
  const name = getRegisteredModuleName(map);
  const depNameArray = depArray.map(getRegisteredModuleName);
  if (modulesGraph.has(name)) {
    // TODO Move this logic to better place
    var previousDeps = modulesGraph.get(name);
    var changed = previousDeps.length != depNameArray.length;
    changed = changed || depNameArray.some(function(depName) {
      return !previousDeps.includes(depName);
    });
    if (changed) {
      console.warn("Dependencies graph change for module '" + name + "' detected. " +
        "Dependencies was [" + previousDeps + "], now [" +  depNameArray.map((depName) => depName) +"]. " +
        "Page can't be hot-reloaded, firing full page reload.");
      window.location.reload();
    }
  } else {
    modulesGraph.set(name, []);
    for (const depName of depNameArray) {
      if (!$dartLoader.moduleParentsGraph.has(depName)) {
        $dartLoader.moduleParentsGraph.set(depName, []);
      }
      $dartLoader.moduleParentsGraph.get(depName).push(name);
      modulesGraph.get(name).push(depName);
    }
  }
};
define("main.client.dart.bootstrap", ["web/main.client", "dart_sdk"], function(app, dart_sdk) {
  
  dart_sdk._isolate_helper.startRootIsolate(() => {}, []);
  var baseUrl = (function () {
  // Attempt to detect --precompiled mode for tests, and set the base url
  // appropriately, otherwise set it to '/'.
  var pathParts = location.pathname.split("/");
  if (pathParts[0] == "") {
    pathParts.shift();
  }
  if (pathParts.length > 1 && pathParts[1] == "test") {
    return "/" + pathParts.slice(0, 2).join("/") + "/";
  }
  // Attempt to detect base url using <base href> html tag
  // base href should start and end with "/"
  if (typeof document !== 'undefined') {
    var el = document.getElementsByTagName('base');
    if (el && el[0] && el[0].getAttribute("href") && el[0].getAttribute
    ("href").startsWith("/") && el[0].getAttribute("href").endsWith("/")){
      return el[0].getAttribute("href");
    }
  }
  // return default value
  return "/";
}());

  dart_sdk._debugger.registerDevtoolsFormatter();
  $dartLoader.getModuleLibraries = dart_sdk.dart.getModuleLibraries;
  if (window.$dartStackTraceUtility && !window.$dartStackTraceUtility.ready) {
    window.$dartStackTraceUtility.ready = true;
    let dart = dart_sdk.dart;
    window.$dartStackTraceUtility.setSourceMapProvider(
      function(url) {
        url = url.replace(baseUrl, '/');
        var module = window.$dartLoader.urlToModuleId.get(url);
        if (!module) return null;
        return dart.getSourceMap(module);
      });
  }
  if (typeof document != 'undefined') {
    window.postMessage({ type: "DDC_STATE_CHANGE", state: "start" }, "*");
  }

  /* MAIN_EXTENSION_MARKER */
  (app.web__main$46client || app.main$46client).main();
  var bootstrap = {
      hot$onChildUpdate: function(childName, child) {
        // Special handling for the multi-root scheme uris. We need to strip
        // out the scheme and the top level directory, to match the source path
        // that chrome sees.
        if (childName.startsWith('org-dartlang-app:///')) {
          childName = childName.substring('org-dartlang-app:///'.length);
          var firstSlash = childName.indexOf('/');
          if (firstSlash == -1) return false;
          childName = childName.substring(firstSlash + 1);
        }
        if (childName === "main.client.dart") {
          // Clear static caches.
          dart_sdk.dart.hotRestart();
          child.main();
          return true;
        }
      }
    }
  dart_sdk.dart.trackLibraries("main.client.dart.bootstrap", {
    "main.client.dart.bootstrap": bootstrap
  }, '');
  return {
    bootstrap: bootstrap
  };
});
})();
