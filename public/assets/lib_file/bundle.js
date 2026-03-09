(() => {
  var t = {
      51: (t, e, n) => {
        "use strict";
        n.r(e), n.d(e, { debounce: () => r });
        var r = function (t) {
          var e;
          return function () {
            for (var n = arguments.length, r = new Array(n), o = 0; o < n; o++)
              r[o] = arguments[o];
            e && cancelAnimationFrame(e),
              (e = requestAnimationFrame(function () {
                t.apply(void 0, r);
              }));
          };
        };
      },
      104: (t, e, n) => {
        "use strict";
        n.r(e), n.d(e, { default: () => r });
        const r = function (t, e) {
          var n =
              arguments.length > 2 && void 0 !== arguments[2]
                ? arguments[2]
                : [],
            r = document.createElement(t),
            o = Object.getOwnPropertyDescriptors(r.__proto__);
          for (var i in e)
            "style" === i
              ? (r.style.cssText = e[i])
              : (o[i] && o[i].set) ||
                /textContent|innerHTML/.test(i) ||
                "function" == typeof e[i]
              ? (r[i] = e[i])
              : r.setAttribute(i, e[i]);
          return (
            n.forEach(function (t) {
              return r.appendChild(t);
            }),
            r
          );
        };
      },
      729: (t, e, n) => {
        "use strict";
        n.r(e), n.d(e, { default: () => o });
        var r =
          "requestIdleCallback" in window
            ? requestIdleCallback
            : function (t) {
                return "complete" == document.readyState
                  ? t()
                  : window.addEventListener("load", function () {
                      return t();
                    });
              };
        const o = function (t) {
          return r(t, {});
        };
      },
      206: (t, e, n) => {
        "use strict";
        function r(t, e) {
          return (
            (function (t) {
              if (Array.isArray(t)) return t;
            })(t) ||
            (function (t, e) {
              if (
                "undefined" == typeof Symbol ||
                !(Symbol.iterator in Object(t))
              )
                return;
              var n = [],
                r = !0,
                o = !1,
                i = void 0;
              try {
                for (
                  var a, u = t[Symbol.iterator]();
                  !(r = (a = u.next()).done) &&
                  (n.push(a.value), !e || n.length !== e);
                  r = !0
                );
              } catch (t) {
                (o = !0), (i = t);
              } finally {
                try {
                  r || null == u.return || u.return();
                } finally {
                  if (o) throw i;
                }
              }
              return n;
            })(t, e) ||
            i(t, e) ||
            (function () {
              throw new TypeError(
                "Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."
              );
            })()
          );
        }
        function o(t) {
          return (
            (function (t) {
              if (Array.isArray(t)) return a(t);
            })(t) ||
            (function (t) {
              if ("undefined" != typeof Symbol && Symbol.iterator in Object(t))
                return Array.from(t);
            })(t) ||
            i(t) ||
            (function () {
              throw new TypeError(
                "Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."
              );
            })()
          );
        }
        function i(t, e) {
          if (t) {
            if ("string" == typeof t) return a(t, e);
            var n = Object.prototype.toString.call(t).slice(8, -1);
            return (
              "Object" === n && t.constructor && (n = t.constructor.name),
              "Map" === n || "Set" === n
                ? Array.from(t)
                : "Arguments" === n ||
                  /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)
                ? a(t, e)
                : void 0
            );
          }
        }
        function a(t, e) {
          (null == e || e > t.length) && (e = t.length);
          for (var n = 0, r = new Array(e); n < e; n++) r[n] = t[n];
          return r;
        }
        n.r(e),
          n.d(e, { monitor: () => p, hydrate: () => h, addPlugin: () => y });
        var u = /(was)? ?(not)? ?@([a-z]+) ?(.*)?/,
          c =
            /(?:was )?(?:not )?@[a-z]+ ?.*?(?:(?= and (?:was )?(?:not )?@[a-z])|$)/g,
          s = function (t) {
            return void 0 === t || "true" === t || ("false" !== t && t);
          },
          l = function (t) {
            var e = r(t.match(u), 5),
              n = e[1],
              o = e[2],
              i = e[3],
              a = e[4];
            return [i, s(a), "not" === o, "was" === n];
          },
          d = function (t, e, n) {
            return (t.invert = e), (t.retain = n), (t.matched = !1), t;
          },
          f = function (t, e, n) {
            var r = b("monitor").find(function (t) {
              return t.name === e;
            });
            if (!r)
              throw new Error(
                'Conditioner: Cannot find monitor with name "@'.concat(
                  e,
                  '". Only the "@media" monitor is always available. Custom monitors can be added with the `addPlugin` method using the `monitors` key. The name of the custom monitor should not include the "@" symbol.'
                )
              );
            return r.create(n, t);
          },
          p = function (t, e) {
            var n = {
                matches: !1,
                active: !1,
                onchange: function () {},
                start: function () {
                  n.active ||
                    ((n.active = !0),
                    r.forEach(function (t) {
                      return t.forEach(function (t) {
                        return t.addListener(i);
                      });
                    }),
                    i());
                },
                stop: function () {
                  (n.active = !1),
                    r.forEach(function (t) {
                      return t.forEach(function (t) {
                        t.removeListener && t.removeListener(i);
                      });
                    });
                },
                destroy: function () {
                  n.stop(), (r.length = 0);
                },
              },
              r = t.split(" or ").map(function (t) {
                return (function (t) {
                  return t.match(c).map(l);
                })(t).map(function (t) {
                  return d.apply(
                    void 0,
                    [f.apply(void 0, [e].concat(o(t)))].concat(o(t.splice(2)))
                  );
                });
              }),
              i = function () {
                var t = r.reduce(function (t, e) {
                  return (
                    !!t ||
                    e.reduce(function (t, e) {
                      if (!t) return !1;
                      var n = e.invert ? !e.matches : e.matches;
                      return (
                        n && (e.matched = !0), !(!e.retain || !e.matched) || n
                      );
                    }, !0)
                  );
                }, !1);
                (n.matches = t), n.onchange(t);
              };
            return n;
          },
          m = function (t) {
            var e = (function (t) {
                var e = A("moduleGetName", t),
                  n = g("moduleSetName", e),
                  r = { destruct: null, mounting: !1 },
                  i = {
                    alias: e,
                    name: n,
                    element: t,
                    mounted: !1,
                    unmount: function () {
                      r.destruct &&
                        i.mounted &&
                        (w("moduleWillUnmount", i),
                        r.destruct(),
                        (i.mounted = !1),
                        w("moduleDidUnmount", i),
                        i.onunmount.apply(t));
                    },
                    mount: function () {
                      if (!i.mounted && !r.mounting)
                        return (
                          w("moduleWillMount", i),
                          A("moduleImport", n)
                            .catch(function (e) {
                              throw (
                                ((r.mounting = !1),
                                w("moduleDidCatch", e, i),
                                i.onmounterror.apply(t, [e, i]),
                                new Error("Conditioner: ".concat(e)))
                              );
                            })
                            .then(function (e) {
                              (r.destruct = A(
                                "moduleGetDestructor",
                                A("moduleGetConstructor", e).apply(
                                  void 0,
                                  o(A("moduleSetConstructorArguments", n, t))
                                )
                              )),
                                (i.mounted = !0),
                                (r.mounting = !1),
                                w("moduleDidMount", i),
                                i.onmount.apply(t, [i]);
                            }),
                          i
                        );
                    },
                    onmounterror: function () {},
                    onmount: function () {},
                    onunmount: function () {},
                    destroy: function () {},
                  };
                return i;
              })(t),
              n = A("moduleGetContext", t);
            return n
              ? (function (t, e) {
                  var n = p(t, e.element);
                  return (
                    (n.onchange = function (t) {
                      return t ? e.mount() : e.unmount();
                    }),
                    n.start(),
                    e
                  );
                })(n, e)
              : e.mount();
          },
          h = function (t) {
            return o(A("moduleSelector", t)).map(m);
          },
          v = [],
          y = function (t) {
            return v.push(t);
          },
          b = function (t) {
            return v
              .filter(function (e) {
                return (n = Object.keys(e)), (r = t), n.indexOf(r) > -1;
                var n, r;
              })
              .map(function (e) {
                return e[t];
              });
          },
          w = function (t) {
            for (
              var e = arguments.length, n = new Array(e > 1 ? e - 1 : 0), r = 1;
              r < e;
              r++
            )
              n[r - 1] = arguments[r];
            return b(t).forEach(function (t) {
              return t.apply(void 0, n);
            });
          },
          g = function (t) {
            for (
              var e = arguments.length, n = new Array(e > 1 ? e - 1 : 0), r = 1;
              r < e;
              r++
            )
              n[r - 1] = arguments[r];
            return b(t)
              .reduce(function (t, e) {
                return [e.apply(void 0, o(t))];
              }, n)
              .shift();
          },
          A = function (t) {
            for (
              var e = arguments.length, n = new Array(e > 1 ? e - 1 : 0), r = 1;
              r < e;
              r++
            )
              n[r - 1] = arguments[r];
            return b(t)
              .pop()
              .apply(void 0, n);
          };
        y({
          moduleSelector: function (t) {
            return t.querySelectorAll("[data-module]");
          },
          moduleGetContext: function (t) {
            return t.dataset.context;
          },
          moduleImport: function (t) {
            return new Promise(function (e, n) {
              if (self[t]) return e(self[t]);
              n(
                'Cannot find module with name "'
                  .concat(
                    t,
                    '". By default Conditioner will import modules from the global scope, make sure a function named "'
                  )
                  .concat(
                    t,
                    '" is defined on the window object. The scope of a function defined with `let` or `const` is limited to the <script> block in which it is defined.'
                  )
              );
            });
          },
          moduleGetConstructor: function (t) {
            return t;
          },
          moduleGetDestructor: function (t) {
            return t;
          },
          moduleSetConstructorArguments: function (t, e) {
            return [e];
          },
          moduleGetName: function (t) {
            return t.dataset.module;
          },
          monitor: {
            name: "media",
            create: function (t) {
              return self.matchMedia(t);
            },
          },
        });
      },
      334: (t, e, n) => {
        "use strict";
        n.r(e), n.d(e, { createFontLoader: () => r });
        var r = function (t, e, n) {
          return function () {
          };
        };
      },
      395: (t, e, n) => {
        "use strict";
        n.r(e);
        var r = n(334),
          o = n(206),
          i = n(245);
        o.addPlugin({
          moduleSetName: function (t) {
            return "./ui/".concat(t, ".js");
          },
          moduleGetConstructor: function (t) {
            return t.default;
          },
          moduleImport: function (t) {
            return n(914)("".concat(t));
          },
        }),
          o.hydrate(document.documentElement),
          (0, r.createFontLoader)(
            window.assetsPath,
            ["woff2"],
            "fonts-loaded"
          )({
            file: "nunito-bold",
            family: "Nunito",
            style: "normal",
            weight: "bold",
          }),
          (window.uploadFile = function (t, e, n, r, o, i) {
            console.log(
              "\n💎 The FilePond file upload process is simulated for privacy reasons.\n"
            );
            var a = 0,
              u = setInterval(function () {
                (a = Math.min(1, a + Math.random() / 15)),
                  i(!0, a, 1),
                  a >= 1 && (clearInterval(u), r(Date.now()));
              }, 100);
          }),
          (window.loadResources = function (t) {
            return new Promise(function (e, n) {
              var r = 0,
                o = function () {
                  ++r === t.length && e();
                };
              t.forEach(function (t) {
                var e = t.split("?")[0];
                /\.css/.test(e)
                  ? (function (t, e) {
                      var n = document.createElement("link");
                      (n.rel = "stylesheet"),
                        (n.href = t),
                        (n.onload = e),
                        document.head.appendChild(n);
                    })(t, o)
                  : /\.js/.test(e) &&
                    (function (t, e) {
                      var n = document.createElement("script");
                      (n.src = t), (n.onload = e), document.head.appendChild(n);
                    })(t, o);
              });
            });
          }),
          window.addEventListener("load", function () {
            Array.from(document.querySelectorAll(".docs [id]:not(h1)"))
              .filter(function (t) {
                return /^h/i.test(t.nodeName);
              })
              .forEach(i.default);
          });
      },
      29: (t, e, n) => {
        "use strict";
        n.r(e), n.d(e, { default: () => r });
        const r = function (t) {
          t.addEventListener("submit", function (e) {
            var n = Date.now();
            e.preventDefault(), (t.dataset.state = "busy");
            var r,
              o,
              i = new FormData(t);
            (r = t.querySelectorAll("input, textarea, button")),
              (o = "disabled"),
              r.forEach(function (t) {
                return t.setAttribute("disabled", o);
              });
            var a = new XMLHttpRequest();
            (a.onload = function () {
              var e = Date.now() - n,
                r = Math.max(0, 1e3 - e);
              setTimeout(function () {
                !(function (e) {
                  var n,
                    r,
                    o = e >= 200 && e < 300;
                  (t.dataset.state = o ? "success" : "error"),
                    o ||
                      ((n = t.querySelectorAll("input, textarea, button")),
                      (r = "disabled"),
                      n.forEach(function (t) {
                        return t.removeAttribute(r);
                      }));
                })(a.status);
              }, r);
            }),
              a.open(
                t.getAttribute("method") || "POST",
                t.getAttribute("action")
              ),
              a.send(i);
          });
        };
      },
      245: (t, e, n) => {
        "use strict";
        n.r(e), n.d(e, { default: () => o });
        var r = n(104);
        const o = function (t) {
          var e = (0, r.default)("a", {
            href: "#".concat(t.id),
            "aria-label": "The ".concat(t.textContent, " section"),
          });
          return (
            (e.innerHTML =
              '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" aria-hidden="true" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"></path><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"></path></svg>'),
            t.appendChild(e),
            function () {
              e.parentNode.removeChild(e);
            }
          );
        };
      },
      238: (t, e, n) => {
        "use strict";
        n.r(e), n.d(e, { default: () => f });
        var r = n(920),
          o = n(104);
        function i(t, e) {
          return (
            (function (t) {
              if (Array.isArray(t)) return t;
            })(t) ||
            (function (t, e) {
              if (
                "undefined" == typeof Symbol ||
                !(Symbol.iterator in Object(t))
              )
                return;
              var n = [],
                r = !0,
                o = !1,
                i = void 0;
              try {
                for (
                  var a, u = t[Symbol.iterator]();
                  !(r = (a = u.next()).done) &&
                  (n.push(a.value), !e || n.length !== e);
                  r = !0
                );
              } catch (t) {
                (o = !0), (i = t);
              } finally {
                try {
                  r || null == u.return || u.return();
                } finally {
                  if (o) throw i;
                }
              }
              return n;
            })(t, e) ||
            l(t, e) ||
            (function () {
              throw new TypeError(
                "Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."
              );
            })()
          );
        }
        function a(t, e) {
          var n = Object.keys(t);
          if (Object.getOwnPropertySymbols) {
            var r = Object.getOwnPropertySymbols(t);
            e &&
              (r = r.filter(function (e) {
                return Object.getOwnPropertyDescriptor(t, e).enumerable;
              })),
              n.push.apply(n, r);
          }
          return n;
        }
        function u(t) {
          for (var e = 1; e < arguments.length; e++) {
            var n = null != arguments[e] ? arguments[e] : {};
            e % 2
              ? a(Object(n), !0).forEach(function (e) {
                  c(t, e, n[e]);
                })
              : Object.getOwnPropertyDescriptors
              ? Object.defineProperties(t, Object.getOwnPropertyDescriptors(n))
              : a(Object(n)).forEach(function (e) {
                  Object.defineProperty(
                    t,
                    e,
                    Object.getOwnPropertyDescriptor(n, e)
                  );
                });
          }
          return t;
        }
        function c(t, e, n) {
          return (
            e in t
              ? Object.defineProperty(t, e, {
                  value: n,
                  enumerable: !0,
                  configurable: !0,
                  writable: !0,
                })
              : (t[e] = n),
            t
          );
        }
        function s(t) {
          return (
            (function (t) {
              if (Array.isArray(t)) return d(t);
            })(t) ||
            (function (t) {
              if ("undefined" != typeof Symbol && Symbol.iterator in Object(t))
                return Array.from(t);
            })(t) ||
            l(t) ||
            (function () {
              throw new TypeError(
                "Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."
              );
            })()
          );
        }
        function l(t, e) {
          if (t) {
            if ("string" == typeof t) return d(t, e);
            var n = Object.prototype.toString.call(t).slice(8, -1);
            return (
              "Object" === n && t.constructor && (n = t.constructor.name),
              "Map" === n || "Set" === n
                ? Array.from(t)
                : "Arguments" === n ||
                  /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)
                ? d(t, e)
                : void 0
            );
          }
        }
        function d(t, e) {
          (null == e || e > t.length) && (e = t.length);
          for (var n = 0, r = new Array(e); n < e; n++) r[n] = t[n];
          return r;
        }
        const f = function (t) {
          var e,
            n = t.textContent.trim(),
            a = (0, o.default)("div"),
            c = "true" === t.dataset.sandbox,
            l = "true" === t.dataset.copy;
          if (c) {
            var d = (function (t) {
              return s(t.querySelectorAll("pre")).map(function (t) {
                var e,
                  n = t.className.match(/language\-([a-z]+)/i)[1],
                  r = t.textContent.split("\n").join("\n");
                return (
                  "html" === n
                    ? ((e = "index.html"),
                      (function (t) {
                        /doctype/i.test(t) ||
                          (t = "<!DOCTYPE html>\n".concat(t));
                      })(r))
                    : /js/.test(n) && (e = "index.js"),
                  { name: e, content: r, type: n }
                );
              });
            })(t);
            if (
              !d.find(function (t) {
                return "html" === t.type;
              })
            ) {
              var f = "";
              d.find(function (t) {
                return "js" === t.type;
              }) &&
                (f =
                  '<form action="/" method="post" enctype="multipart/form-data">\n        <input type="file" name="filepond" multiple />\n\n        <button type="submit">Upload</button>\n        </form>\n\n        <script src="index.js" type="module"></script>'),
                d.push({
                  name: "index.html",
                  content:
                    ((e = f),
                    '\n<!DOCTYPE html>\n<html lang="en">\n    <head>\n        <title>FilePond demo</title>\n        <meta charset="UTF-8">\n        <meta name="viewport" content="width=device-width">\n    </head>\n    <body>\n        '.concat(
                      e,
                      "\n    </body>\n</html>"
                    )),
                });
            }
            var p = d.reduce(function (t, e) {
                return (
                  (t[e.name] = {
                    isBinary: e.isBinary || !1,
                    content: e.content,
                  }),
                  t
                );
              }, {}),
              m = u(
                { filepond: ">=3.7.x < 5.x" },
                (t.dataset.dependencies || "")
                  .split(",")
                  .filter(Boolean)
                  .reduce(function (t, e) {
                    return (t[e] = "latest"), t;
                  }, {})
              ),
              h = u(
                {
                  "package.json": {
                    content: {
                      name: "filepond-demo",
                      version: "0.0.1",
                      description: "A FilePond demo forked from the docs",
                      license: "MIT",
                      repository: "pqina/filepond",
                      main: "index.js",
                      homepage: "https://pqina.nl/filepond",
                      author: { name: "PQINA", url: "https://pqina.nl" },
                      dependencies: m,
                    },
                  },
                },
                (t.dataset.assets || "")
                  .split(",")
                  .filter(Boolean)
                  .reduce(function (t, e) {
                    var n = i(e.split("="), 2),
                      r = n[0],
                      o = n[1];
                    return (
                      (t[r] = {
                        content: "https://pqina.nl/filepond//" + o,
                        isBinary: !0,
                      }),
                      t
                    );
                  }, {})
              ),
              v = {
                template: t.dataset.template || "parcel",
                files: u(u({}, p), h),
              },
              y = (0, o.default)("input", {
                type: "hidden",
                name: "parameters",
                value: (0, r.Z)(v),
              }),
              b = (0, o.default)("button", {
                type: "submit",
                class: "button-fork",
                innerHTML:
                  '<span class="icon"><svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><polygon points="10 8 16 12 10 16 10 8"></polygon></svg></span><span>Run in Sandbox</span>',
              }),
              w = (0, o.default)(
                "form",
                {
                  target: "_blank",
                  method: "post",
                  action: "https://codesandbox.io/api/v1/sandboxes/define",
                },
                [y, b]
              );
            a.appendChild(w);
          }
          if (l) {
            var g = (0, o.default)("button", {
              type: "button",
              class: "button-copy",
              onclick: function () {
                navigator.clipboard &&
                  ((g.dataset.state = "copy"),
                  navigator.clipboard.writeText(n).then(
                    function () {
                      return (g.dataset.state = "copy-success");
                    },
                    function () {
                      return (g.dataset.state = "copy-fail");
                    }
                  ));
              },
              innerHTML:
                '<span class="icon"><svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" ><path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"></path><rect x="8" y="2" width="8" height="4" rx="1" ry="1"></rect>\n            <path class="check" d="M8 10 h2 m3 0 h1 M8 14 h3 m3 0 h2 M8 18 h1 m3 0 h1"/>\n            </svg></span><span>Copy to Clipboard</span>',
            });
            a.appendChild(g);
          }
          return (
            t.appendChild(a),
            function () {
              form.parentNode.removeChild(a);
            }
          );
        };
      },
      704: (t, e, n) => {
        "use strict";
        n.r(e), n.d(e, { default: () => r });
        const r = function (t) {
          window.addEventListener("load", function () {
            t.src = t.dataset.src;
          });
        };
      },
      94: (t, e, n) => {
        "use strict";
        n.r(e), n.d(e, { default: () => r });
        const r = function (t) {
          t.dataset.state = "loading";
          var e = document.createElement("video");
          e.setAttribute("autoplay", ""),
            e.setAttribute("loop", ""),
            (e.muted = !0),
            e.addEventListener("loadeddata", function () {
              (t.dataset.state = "complete"), e.play();
            }),
            t.appendChild(e);
          var n = function () {
            e.innerHTML = '\n        <source src="'.concat(
              t.dataset.videoSrc,
              '" type="video/mp4" />'
            );
          };
          "complete" === document.readyState
            ? n()
            : window.addEventListener("load", n);
        };
      },
      675: (t, e, n) => {
        "use strict";
        n.r(e), n.d(e, { default: () => r });
        const r = function (t) {
          if ("SELECT" !== !t.nodeName) {
            var e = t.dataset.target,
              n = {
                hobby: { type: "Hobby", amount: "one (1) Website" },
                professional: {
                  type: "Professional",
                  amount: "up to five (5) Websites",
                },
                business: { type: "Business", amount: "unlimited Websites" },
              },
              r = function (r) {
                t.value = r;
                var o = n[r];
                document
                  .querySelector(e)
                  .querySelectorAll(".license-field")
                  .forEach(function (t) {
                    t.textContent = o[t.dataset.id];
                  });
              };
            t.addEventListener("change", function (t) {
              r(t.target.value);
            }),
              r(window.location.search.split("=").pop() || t.value);
          }
        };
      },
      911: (t, e, n) => {
        "use strict";
        n.r(e), n.d(e, { default: () => o });
        var r = n(661);
        const o = function (t) {
          var e = function () {
            t.dataset.scroll = window.scrollY;
          };
          document.addEventListener("scroll", (0, r.debounce)(e)), e();
        };
      },
      39: (t, e, n) => {
        "use strict";
        n.r(e), n.d(e, { default: () => r });
        const r = function (t) {
          t.classList.remove("implicit");
          var e = t.nextElementSibling,
            n = document.createElement("button");
          return (
            n.setAttribute("aria-expanded", "false"),
            (n.innerHTML = "".concat(
              t.textContent,
              ' \n\t<svg aria-hidden="true" focusable="false" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-menu"><line x1="3" y1="12" x2="21" y2="12"></line><line x1="3" y1="6" x2="21" y2="6"></line><line x1="3" y1="18" x2="21" y2="18"></line></svg>'
            )),
            (n.onclick = function () {
              var t = "true" === n.getAttribute("aria-expanded") || !1;
              n.setAttribute("aria-expanded", !t), (e.hidden = t);
            }),
            (t.textContent = ""),
            t.appendChild(n),
            (e.hidden = !0),
            function () {
              t.classList.add("implicit"),
                (t.nextElementSibling.hidden = !1),
                (t.textContent = t.firstChild.textContent);
            }
          );
        };
      },
      62: (t, e, n) => {
        "use strict";
        n.r(e), n.d(e, { default: () => r });
        const r = function (t) {
          var e = function (t) {
            var e = t.parentNode,
              n = document.querySelector(t.getAttribute("href"));
            Array.from(t.parentNode.parentNode.querySelectorAll("a")).forEach(
              function (t) {
                t.parentNode.setAttribute("aria-selected", "false");
              }
            ),
              Array.from(n.parentNode.children).forEach(function (t) {
                t.hidden = !0;
              }),
              e.setAttribute("aria-selected", "true"),
              (n.hidden = !1);
          };
          t.addEventListener("click", function (t) {
            "A" === t.target.nodeName &&
              (t.preventDefault(),
              history.pushState(null, "", t.target.getAttribute("href")),
              e(t.target));
          });
          var n = function () {
            var t = window.location.hash;
            if (t) {
              var n = document.querySelector(t);
              if (n) {
                var r = document.getElementById(
                  n.getAttribute("aria-labelledby")
                );
                r && e(r);
              }
            }
          };
          return window.addEventListener("popstate", n), n(), function () {};
        };
      },
      524: (t, e, n) => {
        "use strict";
        n.r(e), n.d(e, { default: () => o });
        var r = n(94);
        const o = function (t) {
          for (
            var e = window.innerWidth <= 640 ? 1 : 4,
              n = function (e) {
                var n = document.createElement("div");
                (n.dataset.videoSrc = t.dataset.videoSrc),
                  setTimeout(function () {
                    (0, r.default)(n);
                  }, 2e3 * e),
                  t.appendChild(n);
              },
              o = 0;
            o < e;
            o++
          )
            n(o);
        };
      },
      661: (t, e, n) => {
        "use strict";
        n.r(e), n.d(e, { debounce: () => r });
        var r = function (t) {
          var e;
          return function () {
            for (var n = arguments.length, r = new Array(n), o = 0; o < n; o++)
              r[o] = arguments[o];
            e && cancelAnimationFrame(e),
              (e = requestAnimationFrame(function () {
                t.apply(void 0, r);
              }));
          };
        };
      },
      412: (t, e, n) => {
        "use strict";
        n.r(e), n.d(e, { getParent: () => r });
        var r = function (t, e) {
          if (t.matches(e)) return t;
          for (var n; (n = t.parentNode); ) if (n.matches(e)) return n;
          return null;
        };
      },
      77: (t, e, n) => {
        "use strict";
        Object.defineProperty(e, "__esModule", { value: !0 }),
          (e.getParameters = void 0);
        var r = n(728);
        e.getParameters = function (t) {
          return (
            (e = JSON.stringify(t)),
            r
              .compressToBase64(e)
              .replace(/\+/g, "-")
              .replace(/\//g, "_")
              .replace(/=+$/, "")
          );
          var e;
        };
      },
      920: (t, e, n) => {
        "use strict";
        e.Z = void 0;
        var r = n(77);
        e.Z = r.getParameters;
      },
      728: (t, e, n) => {
        var r,
          o = (function () {
            var t = String.fromCharCode,
              e =
                "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=",
              n =
                "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+-$",
              r = {};
            function o(t, e) {
              if (!r[t]) {
                r[t] = {};
                for (var n = 0; n < t.length; n++) r[t][t.charAt(n)] = n;
              }
              return r[t][e];
            }
            var i = {
              compressToBase64: function (t) {
                if (null == t) return "";
                var n = i._compress(t, 6, function (t) {
                  return e.charAt(t);
                });
                switch (n.length % 4) {
                  default:
                  case 0:
                    return n;
                  case 1:
                    return n + "===";
                  case 2:
                    return n + "==";
                  case 3:
                    return n + "=";
                }
              },
              decompressFromBase64: function (t) {
                return null == t
                  ? ""
                  : "" == t
                  ? null
                  : i._decompress(t.length, 32, function (n) {
                      return o(e, t.charAt(n));
                    });
              },
              compressToUTF16: function (e) {
                return null == e
                  ? ""
                  : i._compress(e, 15, function (e) {
                      return t(e + 32);
                    }) + " ";
              },
              decompressFromUTF16: function (t) {
                return null == t
                  ? ""
                  : "" == t
                  ? null
                  : i._decompress(t.length, 16384, function (e) {
                      return t.charCodeAt(e) - 32;
                    });
              },
              compressToUint8Array: function (t) {
                for (
                  var e = i.compress(t),
                    n = new Uint8Array(2 * e.length),
                    r = 0,
                    o = e.length;
                  r < o;
                  r++
                ) {
                  var a = e.charCodeAt(r);
                  (n[2 * r] = a >>> 8), (n[2 * r + 1] = a % 256);
                }
                return n;
              },
              decompressFromUint8Array: function (e) {
                if (null == e) return i.decompress(e);
                for (
                  var n = new Array(e.length / 2), r = 0, o = n.length;
                  r < o;
                  r++
                )
                  n[r] = 256 * e[2 * r] + e[2 * r + 1];
                var a = [];
                return (
                  n.forEach(function (e) {
                    a.push(t(e));
                  }),
                  i.decompress(a.join(""))
                );
              },
              compressToEncodedURIComponent: function (t) {
                return null == t
                  ? ""
                  : i._compress(t, 6, function (t) {
                      return n.charAt(t);
                    });
              },
              decompressFromEncodedURIComponent: function (t) {
                return null == t
                  ? ""
                  : "" == t
                  ? null
                  : ((t = t.replace(/ /g, "+")),
                    i._decompress(t.length, 32, function (e) {
                      return o(n, t.charAt(e));
                    }));
              },
              compress: function (e) {
                return i._compress(e, 16, function (e) {
                  return t(e);
                });
              },
              _compress: function (t, e, n) {
                if (null == t) return "";
                var r,
                  o,
                  i,
                  a = {},
                  u = {},
                  c = "",
                  s = "",
                  l = "",
                  d = 2,
                  f = 3,
                  p = 2,
                  m = [],
                  h = 0,
                  v = 0;
                for (i = 0; i < t.length; i += 1)
                  if (
                    ((c = t.charAt(i)),
                    Object.prototype.hasOwnProperty.call(a, c) ||
                      ((a[c] = f++), (u[c] = !0)),
                    (s = l + c),
                    Object.prototype.hasOwnProperty.call(a, s))
                  )
                    l = s;
                  else {
                    if (Object.prototype.hasOwnProperty.call(u, l)) {
                      if (l.charCodeAt(0) < 256) {
                        for (r = 0; r < p; r++)
                          (h <<= 1),
                            v == e - 1 ? ((v = 0), m.push(n(h)), (h = 0)) : v++;
                        for (o = l.charCodeAt(0), r = 0; r < 8; r++)
                          (h = (h << 1) | (1 & o)),
                            v == e - 1 ? ((v = 0), m.push(n(h)), (h = 0)) : v++,
                            (o >>= 1);
                      } else {
                        for (o = 1, r = 0; r < p; r++)
                          (h = (h << 1) | o),
                            v == e - 1 ? ((v = 0), m.push(n(h)), (h = 0)) : v++,
                            (o = 0);
                        for (o = l.charCodeAt(0), r = 0; r < 16; r++)
                          (h = (h << 1) | (1 & o)),
                            v == e - 1 ? ((v = 0), m.push(n(h)), (h = 0)) : v++,
                            (o >>= 1);
                      }
                      0 == --d && ((d = Math.pow(2, p)), p++), delete u[l];
                    } else
                      for (o = a[l], r = 0; r < p; r++)
                        (h = (h << 1) | (1 & o)),
                          v == e - 1 ? ((v = 0), m.push(n(h)), (h = 0)) : v++,
                          (o >>= 1);
                    0 == --d && ((d = Math.pow(2, p)), p++),
                      (a[s] = f++),
                      (l = String(c));
                  }
                if ("" !== l) {
                  if (Object.prototype.hasOwnProperty.call(u, l)) {
                    if (l.charCodeAt(0) < 256) {
                      for (r = 0; r < p; r++)
                        (h <<= 1),
                          v == e - 1 ? ((v = 0), m.push(n(h)), (h = 0)) : v++;
                      for (o = l.charCodeAt(0), r = 0; r < 8; r++)
                        (h = (h << 1) | (1 & o)),
                          v == e - 1 ? ((v = 0), m.push(n(h)), (h = 0)) : v++,
                          (o >>= 1);
                    } else {
                      for (o = 1, r = 0; r < p; r++)
                        (h = (h << 1) | o),
                          v == e - 1 ? ((v = 0), m.push(n(h)), (h = 0)) : v++,
                          (o = 0);
                      for (o = l.charCodeAt(0), r = 0; r < 16; r++)
                        (h = (h << 1) | (1 & o)),
                          v == e - 1 ? ((v = 0), m.push(n(h)), (h = 0)) : v++,
                          (o >>= 1);
                    }
                    0 == --d && ((d = Math.pow(2, p)), p++), delete u[l];
                  } else
                    for (o = a[l], r = 0; r < p; r++)
                      (h = (h << 1) | (1 & o)),
                        v == e - 1 ? ((v = 0), m.push(n(h)), (h = 0)) : v++,
                        (o >>= 1);
                  0 == --d && ((d = Math.pow(2, p)), p++);
                }
                for (o = 2, r = 0; r < p; r++)
                  (h = (h << 1) | (1 & o)),
                    v == e - 1 ? ((v = 0), m.push(n(h)), (h = 0)) : v++,
                    (o >>= 1);
                for (;;) {
                  if (((h <<= 1), v == e - 1)) {
                    m.push(n(h));
                    break;
                  }
                  v++;
                }
                return m.join("");
              },
              decompress: function (t) {
                return null == t
                  ? ""
                  : "" == t
                  ? null
                  : i._decompress(t.length, 32768, function (e) {
                      return t.charCodeAt(e);
                    });
              },
              _decompress: function (e, n, r) {
                var o,
                  i,
                  a,
                  u,
                  c,
                  s,
                  l,
                  d = [],
                  f = 4,
                  p = 4,
                  m = 3,
                  h = "",
                  v = [],
                  y = { val: r(0), position: n, index: 1 };
                for (o = 0; o < 3; o += 1) d[o] = o;
                for (a = 0, c = Math.pow(2, 2), s = 1; s != c; )
                  (u = y.val & y.position),
                    (y.position >>= 1),
                    0 == y.position &&
                      ((y.position = n), (y.val = r(y.index++))),
                    (a |= (u > 0 ? 1 : 0) * s),
                    (s <<= 1);
                switch (a) {
                  case 0:
                    for (a = 0, c = Math.pow(2, 8), s = 1; s != c; )
                      (u = y.val & y.position),
                        (y.position >>= 1),
                        0 == y.position &&
                          ((y.position = n), (y.val = r(y.index++))),
                        (a |= (u > 0 ? 1 : 0) * s),
                        (s <<= 1);
                    l = t(a);
                    break;
                  case 1:
                    for (a = 0, c = Math.pow(2, 16), s = 1; s != c; )
                      (u = y.val & y.position),
                        (y.position >>= 1),
                        0 == y.position &&
                          ((y.position = n), (y.val = r(y.index++))),
                        (a |= (u > 0 ? 1 : 0) * s),
                        (s <<= 1);
                    l = t(a);
                    break;
                  case 2:
                    return "";
                }
                for (d[3] = l, i = l, v.push(l); ; ) {
                  if (y.index > e) return "";
                  for (a = 0, c = Math.pow(2, m), s = 1; s != c; )
                    (u = y.val & y.position),
                      (y.position >>= 1),
                      0 == y.position &&
                        ((y.position = n), (y.val = r(y.index++))),
                      (a |= (u > 0 ? 1 : 0) * s),
                      (s <<= 1);
                  switch ((l = a)) {
                    case 0:
                      for (a = 0, c = Math.pow(2, 8), s = 1; s != c; )
                        (u = y.val & y.position),
                          (y.position >>= 1),
                          0 == y.position &&
                            ((y.position = n), (y.val = r(y.index++))),
                          (a |= (u > 0 ? 1 : 0) * s),
                          (s <<= 1);
                      (d[p++] = t(a)), (l = p - 1), f--;
                      break;
                    case 1:
                      for (a = 0, c = Math.pow(2, 16), s = 1; s != c; )
                        (u = y.val & y.position),
                          (y.position >>= 1),
                          0 == y.position &&
                            ((y.position = n), (y.val = r(y.index++))),
                          (a |= (u > 0 ? 1 : 0) * s),
                          (s <<= 1);
                      (d[p++] = t(a)), (l = p - 1), f--;
                      break;
                    case 2:
                      return v.join("");
                  }
                  if ((0 == f && ((f = Math.pow(2, m)), m++), d[l])) h = d[l];
                  else {
                    if (l !== p) return null;
                    h = i + i.charAt(0);
                  }
                  v.push(h),
                    (d[p++] = i + h.charAt(0)),
                    (i = h),
                    0 == --f && ((f = Math.pow(2, m)), m++);
                }
              },
            };
            return i;
          })();
        void 0 ===
          (r = function () {
            return o;
          }.call(e, n, e, t)) || (t.exports = r);
      },
      914: (t, e, n) => {
        var r = {
          ".": 395,
          "./": 395,
          "./common/debounce": 51,
          "./common/debounce.js": 51,
          "./common/h": 104,
          "./common/h.js": 104,
          "./common/pushToIdleMoment": 729,
          "./common/pushToIdleMoment.js": 729,
          "./conditioner-core": 206,
          "./conditioner-core.js": 206,
          "./createFontLoader": 334,
          "./createFontLoader.js": 334,
          "./index": 395,
          "./index.js": 395,
          "./ui/AsyncForm": 29,
          "./ui/AsyncForm.js": 29,
          "./ui/Bookmark": 245,
          "./ui/Bookmark.js": 245,
          "./ui/CodeControl": 238,
          "./ui/CodeControl.js": 238,
          "./ui/LazyImage": 704,
          "./ui/LazyImage.js": 704,
          "./ui/LazyVideo": 94,
          "./ui/LazyVideo.js": 94,
          "./ui/LicenseFormatter": 675,
          "./ui/LicenseFormatter.js": 675,
          "./ui/ScrollTracker": 911,
          "./ui/ScrollTracker.js": 911,
          "./ui/SectionToggler": 39,
          "./ui/SectionToggler.js": 39,
          "./ui/TabList": 62,
          "./ui/TabList.js": 62,
          "./ui/TiledVideo": 524,
          "./ui/TiledVideo.js": 524,
          "./utils/debounce": 661,
          "./utils/debounce.js": 661,
          "./utils/getParent": 412,
          "./utils/getParent.js": 412,
        };
        function o(t) {
          return i(t).then(n);
        }
        function i(t) {
          return Promise.resolve().then(() => {
            if (!n.o(r, t)) {
              var e = new Error("Cannot find module '" + t + "'");
              throw ((e.code = "MODULE_NOT_FOUND"), e);
            }
            return r[t];
          });
        }
        (o.keys = () => Object.keys(r)),
          (o.resolve = i),
          (o.id = 914),
          (t.exports = o);
      },
    },
    e = {};
  function n(r) {
    if (e[r]) return e[r].exports;
    var o = (e[r] = { exports: {} });
    return t[r](o, o.exports, n), o.exports;
  }
  (n.d = (t, e) => {
    for (var r in e)
      n.o(e, r) &&
        !n.o(t, r) &&
        Object.defineProperty(t, r, { enumerable: !0, get: e[r] });
  }),
    (n.o = (t, e) => Object.prototype.hasOwnProperty.call(t, e)),
    (n.r = (t) => {
      "undefined" != typeof Symbol &&
        Symbol.toStringTag &&
        Object.defineProperty(t, Symbol.toStringTag, { value: "Module" }),
        Object.defineProperty(t, "__esModule", { value: !0 });
    }),
    n(395);
})();
