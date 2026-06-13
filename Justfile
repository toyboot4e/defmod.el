# mod.el development tasks.  `just ci` runs everything.

emacs := "emacs"
stage := ".stage"

default: ci

ci: compile lint test

# Staged byte-compilation with warnings as errors.
[private]
alias c := compile
compile:
    #!/usr/bin/env bash
    set -euo pipefail
    rm -rf "{{ stage }}" && mkdir -p "{{ stage }}"
    cp lisp/defmod.el "{{ stage }}/"
    "{{ emacs }}" -Q --batch -L "{{ stage }}" \
        --eval '(setq byte-compile-error-on-warn t)' \
        -f batch-byte-compile "{{ stage }}/defmod.el"
    echo "compiled: defmod"

# Run the ERT suite in batch.
[private]
alias t := test
test:
    "{{ emacs }}" -Q --batch -L lisp -L test \
        -l defmod-test \
        -f ert-run-tests-batch-and-exit

# package-lint and checkdoc, BOTH failing (stricter than aim-mode).
[private]
alias l := lint
lint:
    #!/usr/bin/env bash
    set -euo pipefail
    # package-lint, with ONE category false-positive suppressed: defmod
    # EMITS user configuration, so `with-eval-after-load' in the generated
    # code is that macro's sanctioned use, not a library misusing load
    # order.  package-lint's check is a plain text regexp that cannot tell
    # the difference.  Every other warning stays fatal.
    "{{ emacs }}" -Q --batch -l package-lint \
        --eval '(setq package-lint-main-file "lisp/defmod.el")' \
        --eval '(progn
                  (package-initialize)
                  (let ((text-quoting-style (quote grave)) (any nil))
                    (dolist (file (directory-files "lisp" t "\\.el$"))
                      (with-temp-buffer
                        (insert-file-contents file t)
                        (emacs-lisp-mode)
                        (dolist (r (package-lint-buffer))
                          (unless (string-match-p "eval-after-load" (nth 3 r))
                            (setq any t)
                            (message "%s:%d:%d: %s: %s"
                                     file (nth 0 r) (nth 1 r) (nth 2 r) (nth 3 r))))))
                    (kill-emacs (if any 1 0))))'
    # Load the package first: checkdoc accepts message text starting with
    # a DEFINED symbol, which is how the "defmod NAME: ..." error format
    # passes the capitalization check.
    out=$("{{ emacs }}" -Q --batch -L lisp -l defmod \
        --eval '(dolist (f (directory-files "lisp" t "\\.el$")) (checkdoc-file f))' 2>&1)
    if [ -n "$out" ]; then
        echo "$out"
        echo "checkdoc: FAIL"
        exit 1
    fi
    echo "checkdoc: clean"

clean:
    rm -rf "{{ stage }}" lisp/*.elc test/*.elc
