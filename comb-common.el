;;; comb-common.el --- Common utilities -*- lexical-binding: t -*-

;;; Code:

(require 'comb-session)

(require 'cl-macs)

(defface comb-match '((t :inherit match))
  "Face used to highlight the matches."
  :group 'comb)

(defface comb-undecided '((t :inherit shadow))
  "Face used to mark undecided results."
  :group 'comb)

(defface comb-approved '((t :inherit success))
  "Face used to mark approved results."
  :group 'comb)

(defface comb-rejected '((t :inherit error))
  "Face used to mark rejected results."
  :group 'comb)

(defface comb-notes '((t :inherit font-lock-comment-face))
  "Face used to display the notes."
  :group 'comb)

(defvar comb--window-configuration nil
  "Window configuration snapshot.")

(defun comb--format-status (status)
  "Format result STATUS."
  (cl-case status
    ('nil (propertize "UNDECIDED" 'face 'comb-undecided))
    ('approved (propertize "APPROVED" 'face 'comb-approved))
    ('rejected (propertize "REJECTED" 'face 'comb-rejected))))

(defun comb--format-notes (notes)
  "Format result NOTES."
  (propertize notes 'face 'comb-notes))

(defun comb--format-file-location (path &optional line)
  "Format file location (PATH and LINE)."
  (format "%s%s%s"
          (or (file-name-directory path) "")
          (propertize (file-name-nondirectory path) 'face 'bold)
          (if line (propertize (format ":%s" line) 'face 'shadow) "")))

(defun comb--save-window-configuration ()
  "Save current window configuration if needed."
  (unless comb--window-configuration
    (setq comb--window-configuration (current-window-configuration))))

(defun comb--restore-window-configuration ()
  "Restore the saved window configuration, if any."
  (when comb--window-configuration
    (set-window-configuration comb--window-configuration)
    (setq comb--window-configuration nil)))

(defmacro comb--with-temp-buffer-window (name on-exit keymap &rest body)
  "Create a disposable buffer named NAME.

The ON-EXIT form is executed when the user presses 'q'.

If KEYMAP is not nil the use it as a parent keymap.

BODY is executed in the context of the newly created buffer."
  ;; show a fresh new buffer
  `(let ((name ,name))
     (ignore-errors (kill-buffer name))
     (with-current-buffer (switch-to-buffer name)
       ;; setup keymap
       (let ((keymap (make-sparse-keymap)))
         (set-keymap-parent keymap ,keymap)
         (suppress-keymap keymap)
         (define-key keymap (kbd "q")
           (lambda () (interactive) ,on-exit))
         (use-local-map keymap))
       ;; user body
       (let ((inhibit-read-only t)) ,@body)
       (set-buffer-modified-p nil))))

(defun comb--valid-cursor-p (&optional cursor)
  "Return non-nil if the cursor (or CURSOR) is valid."
  (let ((cursor (or cursor (comb--cursor))))
    (and (>= cursor 0) (< cursor (length (comb--results))))))

(defun comb--get-result (&optional cursor)
  "Get the result under the cursor (or CURSOR)."
  (aref (comb--results) (or cursor (comb--cursor))))

(defun comb--get-info (&optional result)
  "Obtain the information associated to the current result (or RESULT)."
  (gethash (or result (comb--get-result)) (comb--infos)))

(defmacro comb--with-info (info &rest body)
  "Utility to modify the information associated access the current result.

INFO is the name of the information variable used in BODY."
  `(condition-case nil
       (let (result ,info)
         ;; get result
         (setq result (comb--get-result))
         ;; get associated info
         (setq ,info (gethash result (comb--infos) (cons nil nil)))
         ;; execute the user-provided body using info
         ,@body
         ;; update only if needed
         (unless (equal ,info (cons nil nil))
           (puthash result ,info (comb--infos))))
     (args-out-of-range nil)))

(provide 'comb-common)

;;; comb-common.el ends here
