;;; org-super-links-peek.el --- Take a peek at the content of link target  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  tosh

;; Author: tosh <tosh.lyons@gmail.com>
;; Version: 0.4
;; Package-Requires: ((emacs "24.1") (quick-peek "1.0"))
;; URL: https://github.com/toshism/org-super-links-peek
;; Keywords: convenience, hypermedia

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Use the quick-peek package to take a peek at the target of links.
;; Mostly just a dumber version of org-quick-peek to only handle links.

;;; Code:

(require 'org)
(require 'quick-peek)

(defvar org-drawer-regexp)
(defvar org-super-links-peek-show-lines 10)
(defvar org-super-links-peek-show-drawers nil)

(defun org-super-links-peek--marker-target-link ()
  "Return marker for link at point."
  (save-window-excursion
    (org-open-at-point)
    (point-marker)))

(defun org-super-links-peek--get-entry-text (marker keep-drawers num-lines)
  "Return Org entry text from node at MARKER.
If KEEP-DRAWERS is non-nil, drawers will be kept, otherwise
removed.  If NUM-LINES is non-nil, only return the first that
many lines."
  ;; Modeled after `org-agenda-get-some-entry-text'
  ;; Stolen from https://github.com/alphapapa/org-quick-peek
  ;; thanks alphapapa!
  (let (text)
    (with-current-buffer (marker-buffer marker)
      ;; Get raw entry text
      (org-with-wide-buffer
       (goto-char marker)
       ;; Skip heading
       (end-of-line 1)
       ;; Get entry text
       (setq text (buffer-substring
                   (point)
                   (or (save-excursion (outline-next-heading) (point))
		       (point-max))))))
    (unless keep-drawers
      (with-temp-buffer
        ;; Insert entry in temp buffer and remove drawers
        (insert text)
        (goto-char (point-min))
        (while (re-search-forward org-drawer-regexp nil t)
          ;; Remove drawers
          (delete-region (match-beginning 0)
                         (progn (re-search-forward
                                 "^[ \t]*:END:.*\n?" nil 'move)
                                (point))))
        (setq text (buffer-substring (point-min) (point-max)))))
    (when num-lines
      ;; Remove extra lines
      (with-temp-buffer
        (insert text)
        (goto-char (point-min))
        (org-goto-line (1+ num-lines))
        (backward-char 1)
        (setq text (buffer-substring (point-min) (point-max)))))
    text))

(defun org-super-links-peek-link ()
  "Show quick peek of Org heading linked at point."
  (interactive)
  (let ((m (point-marker)))
    (unless (> (quick-peek-hide (marker-position m)) 0)
      ;; Showing, not hiding
      (save-excursion
	(let ((target-marker (org-super-links-peek--marker-target-link)))
	  (quick-peek-show (org-super-links-peek--get-entry-text target-marker
								 org-super-links-peek-show-drawers
								 org-super-links-peek-show-lines)
			   (marker-position m)))))))

(provide 'org-super-links-peek)
;;; org-super-links-peek.el ends here
