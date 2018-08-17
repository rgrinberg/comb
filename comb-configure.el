;;; comb-setup.el --- Configuration buffer -*- lexical-binding: t -*-

;;; Code:

(require 'comb-common)
(require 'comb-search)
(require 'comb-session)

(require 'wid-edit)
(require 'seq)

(declare-function comb--display "comb-browse")

(defvar comb--root-widget)
(defvar comb--patterns-widget)
(defvar comb--include-files-widget)
(defvar comb--exclude-paths-widget)

(defun comb--configure ()
  "Show the configuration buffer."
  (comb--with-temp-buffer-window
   "*Comb: configure*"
   ;; on quit
   (comb--configuration-quit)
   ;; keymap
   (let ((keymap (make-sparse-keymap)))
     (set-keymap-parent keymap widget-keymap)
     (define-key keymap (kbd "R")
       (lambda () (interactive) (comb--configuration-load-ui)))
     (define-key keymap (kbd "S")
       (lambda () (interactive) (comb--configuration-search)))
     keymap)
   ;; add root directory
   (widget-insert "In directory (absolute path):\n\n")
   (setq comb--root-widget (comb--create-directory-widget))
   (widget-insert "\n")
   ;; add regexp lists
   (widget-insert "Search for:\n\n")
   (setq comb--patterns-widget (comb--create-list-widget "\\<word\\>"))
   (widget-insert "\n")
   (widget-insert "Including file names matching:\n\n")
   (setq comb--include-files-widget (comb--create-list-widget "\\.extension$"))
   (widget-insert "\n")
   (widget-insert "Excluding directory names matching:\n\n")
   (setq comb--exclude-paths-widget (comb--create-list-widget "^some/directory$"))
   (widget-insert "\n")
   ;; add search and reset buttons
   (comb--create-button-widget "(R)eset" #'comb--configuration-load-ui)
   (widget-insert " ")
   (comb--create-button-widget "(S)earch" #'comb--configuration-search)
   (widget-insert "\n")
   ;; finalize
   (widget-setup)
   (comb--configuration-load-ui)
   (goto-char (point-min))))

(defun comb--create-list-widget (placeholder)
  "Editable list widget using PLACEHOLDER as a default value."
  (widget-create
   'editable-list
   :entry-format "%d %v"
   :delete-button-args '(:tag "-")
   :append-button-args '(:tag "+")
   `(cons :format "%v"
          ;; [] consistency with buttons
          (toggle :format ,(format "%%[%s%%v%s%%]"
                                   widget-push-button-prefix
                                   widget-push-button-suffix)
                  :on "✓" :off "✗" :value t
                  :help-echo "Toggle this item")
          (regexp :format " %v" :value ,placeholder))))

(defun comb--create-button-widget (tag action)
  "Button widget given TAG and ACTION."
  (widget-create 'push-button :tag tag
                 :notify (lambda (&rest _) (funcall action))))

(defun comb--create-directory-widget ()
  "Directory input widget."
  (widget-create 'directory :format "%v"))

;; configuration commands

(defun comb--configuration-load-ui ()
  "Populate the GUI using the current session."
  (save-mark-and-excursion
    (widget-value-set comb--root-widget (comb--root))
    (widget-value-set comb--patterns-widget (comb--patterns))
    (widget-value-set comb--include-files-widget (comb--include-files))
    (widget-value-set comb--exclude-paths-widget (comb--exclude-paths))
    (widget-setup)
    (set-buffer-modified-p nil)))

(defun comb--configuration-save-ui ()
  "Apply the GUI changes to the current session."
  (setf (comb--root) (widget-value comb--root-widget))
  (setf (comb--patterns) (widget-value comb--patterns-widget))
  (setf (comb--include-files) (widget-value comb--include-files-widget))
  (setf (comb--exclude-paths) (widget-value comb--exclude-paths-widget))
  (set-buffer-modified-p nil))

(defun comb--configuration-search ()
  "Start a new search from the configuration buffer."
  (comb--configuration-save-ui)
  (redisplay) ; allow to show the unmodified mark immediately
  (if (comb--search)
      (progn (kill-buffer) (comb--display))
    ;; just update it in the background
    (comb--display t)))

(defun comb--configuration-quit ()
  "Quit the configuration buffer committing changes to the session."
  (comb--configuration-save-ui)
  (kill-buffer))

(provide 'comb-configure)

;;; comb-configure.el ends here
