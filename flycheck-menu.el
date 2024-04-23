;;; flycheck-menu.el --- Transient menu for flycheck -*- lexical-binding: t; -*-

;; Copyright (C) 2024 Karim Aziiev <karim.aziiev@gmail.com>

;; Author: Karim Aziiev <karim.aziiev@gmail.com>
;; URL: https://github.com/KarimAziev/flycheck-menu
;; Version: 0.1.0
;; Keywords: tools
;; Package-Requires: ((emacs "28.1") (flycheck "32") (transient "0.6.0"))
;; SPDX-License-Identifier: GPL-3.0-or-later

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Transient menu for flycheck

;;; Code:


(require 'flycheck)
(require 'transient)

(defun flycheck-menu--format-toggle-description (description value &optional
                                                             on-label off-label
                                                             left-separator
                                                             right-separator
                                                             divider)
  "Format toggle DESCRIPTION with VALUE indication and optional labels.

Argument DESCRIPTION is the text description of the toggle.

Argument VALUE is a boolean indicating the toggle's state.

Optional argument ON-LABEL is the label shown when VALUE is non-nil. It defaults
to \"+\".

Optional argument OFF-LABEL is the label shown when VALUE is nil. It defaults to
\"-\".

Optional argument LEFT-SEPARATOR is the character used before the ON-LABEL or
OFF-LABEL. It defaults to \"[\".

Optional argument RIGHT-SEPARATOR is the character used after the ON-LABEL or
OFF-LABEL. It defaults to \"]\".

Optional argument DIVIDER is the character used to fill space. It defaults to 32
\\=(space character)."
  (let* ((description (or description ""))
         (face (if value 'success 'transient-inactive-value)))
    (concat
     (truncate-string-to-width description 30
                               nil (or divider ?\s) t)
     (or left-separator "[")
     (if value
         (propertize
          (or on-label "+")
          'face
          face)
       (propertize
        (or off-label "-")
        'face
        face))
     (or right-separator "]"))))



;;;###autoload (autoload 'flycheck-menu "flycheck-menu" nil t)
(transient-define-prefix flycheck-menu ()
  "Menu with Flycheck commands and settings."
  :refresh-suffixes t
  [:description
   (lambda ()
     (concat (if flycheck-mode
                 "Current"
               "Available")
             " "
             (format "Checker (%s)"
                     (or (flycheck-checker-at-point)
                         (ignore-errors (flycheck-get-checker-for-buffer))))))
   ("m" flycheck-mode
    :description (lambda ()
                   (concat "Turn "
                           (if flycheck-mode
                               "Off"
                             "On")
                           " "
                           (flycheck-menu--format-toggle-description
                            "Flycheck Mode"
                            flycheck-mode)))
    :inapt-if-not (lambda ()
                    (seq-find
                     #'flycheck-checker-supports-major-mode-p
                     flycheck-checkers))
    :transient t)
   ("c" "Check current buffer" flycheck-buffer :inapt-if-nil
    flycheck-mode)
   ""
   ("M-n" "Go to next error" flycheck-next-error
    :transient t
    :inapt-if-nil
    flycheck-mode)
   ("M-p" "Go to previous error" flycheck-previous-error
    :transient t
    :inapt-if-nil
    flycheck-mode)]
  ["Errors"
   [("l" "Show all errors" flycheck-list-errors :inapt-if-nil
     flycheck-mode)
    ("C" "Clear errors in buffer" flycheck-clear)]
   [("w" "Copy messages at point" flycheck-copy-errors-as-kill
     :inapt-if-not
     (lambda ()
       (flycheck-overlays-at (point))))
    ("x" "Explain error at point" flycheck-explain-error-at-point
     :inapt-if-not (lambda ()
                     (when-let* ((first-error
                                  (seq-find (lambda (error)
                                              (flycheck-checker-get
                                               (flycheck-error-checker error)
                                               'error-explainer))
                                            (flycheck-overlay-errors-at (point))))
                                 (explainer
                                  (flycheck-checker-get (flycheck-error-checker
                                                         first-error)
                                                        'error-explainer)))
                       (funcall explainer first-error))))]]
  ["Settings"
   [("s" "Select syntax checker" flycheck-select-checker :inapt-if-nil
     flycheck-mode)
    ("D" "Disable syntax checker" flycheck-disable-checker :inapt-if-nil
     flycheck-mode)
    ("X" "Set executable of syntax checker" flycheck-set-checker-executable
     :inapt-if-nil
     flycheck-mode)
    ("d" "Describe syntax checker" flycheck-describe-checker)]
   [("v" "Verify setup" flycheck-verify-setup)
    ("V" "Show Flycheck version" flycheck-version)
    ("i" "Read the Flycheck manual" flycheck-manual)]])

(provide 'flycheck-menu)
;;; flycheck-menu.el ends here