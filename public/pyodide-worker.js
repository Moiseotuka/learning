/* Exécution du code apprenant dans un Web Worker isolé.
   L'interface reste réactive ; une boucle infinie est tuable depuis le client
   (terminate) sans figer l'onglet.
   - Python : Pyodide (CPython en WebAssembly, chargé depuis le CDN jsDelivr)
   - JavaScript : évaluation contrôlée avec console détournée vers la sortie */
"use strict";

var PYODIDE_VERSION = "v0.28.0";
var PYODIDE_INDEX = "https://cdn.jsdelivr.net/pyodide/" + PYODIDE_VERSION + "/full/";

var pyodidePromise = null;

/* input() n'a pas de clavier dans un worker : on remplace la fonction built-in
   par un message clair plutôt que par un plantage sur prompt(). */
var INPUT_PATCH = [
  "import builtins",
  "def _easylearn_input(prompt=''):",
  "    raise RuntimeError(",
  "        \"input() n'est pas disponible dans cet editeur : \"",
  "        + \"remplacez input(...) par une valeur en dur (par exemple 15) \"",
  "        + \"puis relancez l'execution.\"",
  "    )",
  "builtins.input = _easylearn_input",
].join("\n");

function getPyodide() {
  if (!pyodidePromise) {
    importScripts(PYODIDE_INDEX + "pyodide.js");
    pyodidePromise = self
      .loadPyodide({ indexURL: PYODIDE_INDEX })
      .then(function (pyodide) {
        pyodide.runPython(INPUT_PATCH);
        return pyodide;
      });
  }
  return pyodidePromise;
}

function formatValue(value) {
  if (typeof value === "string") return value;
  try {
    return JSON.stringify(value);
  } catch {
    return String(value);
  }
}

/* Retire les frames internes de Pyodide : le traceback commence à la ligne
   du code apprenant (File "<exec>"), plus lisible pour l'étudiant. */
function cleanPythonTraceback(message) {
  var marker = 'File "<exec>"';
  var at = message.indexOf(marker);
  if (at < 0) return message;
  var lineStart = message.lastIndexOf("\n", at) + 1;
  return "Traceback (most recent call last):\n" + message.slice(lineStart);
}

function runJavaScript(code) {
  var lines = [];
  var sandboxConsole = {
    log: function () {
      lines.push(Array.prototype.map.call(arguments, formatValue).join(" "));
    },
    info: function () {
      lines.push(Array.prototype.map.call(arguments, formatValue).join(" "));
    },
    warn: function () {
      lines.push(Array.prototype.map.call(arguments, formatValue).join(" "));
    },
    debug: function () {
      lines.push(Array.prototype.map.call(arguments, formatValue).join(" "));
    },
    error: function () {
      lines.push(Array.prototype.map.call(arguments, formatValue).join(" "));
    },
  };
  var runner = new Function("console", '"use strict";\n' + code);
  runner(sandboxConsole);
  return lines.join("\n");
}

self.onmessage = function (event) {
  var id = event.data && event.data.id;
  var language = event.data && event.data.language;
  var code = event.data && typeof event.data.code === "string" ? event.data.code : "";

  var stdout = "";
  var stderr = "";

  function reply(payload) {
    payload.id = id;
    payload.stdout = stdout + (payload.stdout || "");
    payload.stderr = stderr + (payload.stderr || "");
    self.postMessage(payload);
  }

  var work;
  if (language === "python") {
    work = getPyodide().then(function (pyodide) {
      pyodide.setStdout({
        batched: function (text) {
          stdout += text + "\n";
        },
      });
      pyodide.setStderr({
        batched: function (text) {
          stderr += text + "\n";
        },
      });
      return pyodide.runPythonAsync(code);
    });
  } else {
    try {
      reply({ ok: true, stdout: runJavaScript(code), stderr: "" });
      return;
    } catch (error) {
      reply({
        ok: false,
        stdout: "",
        stderr: "",
        error: error && error.message ? error.message : String(error),
      });
      return;
    }
  }

  work.then(
    function () {
      reply({ ok: true, stdout: "", stderr: "" });
    },
    function (error) {
      reply({
        ok: false,
        stdout: "",
        stderr: "",
        error: cleanPythonTraceback(
          error && error.message ? error.message : String(error),
        ),
      });
    },
  );
};
