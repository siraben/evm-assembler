
;;; Code:
(setq actorforth-highlights
      '(
        ("begin\\|while\\|endwhile\\|case\\|endcase\\|if\\|endif\\|->\\|down_to\\|loop" . font-lock-keyword-face)
        ("False\\|True\\|Nothing\\|Just" . font-lock-constant-face)
        ("\\(^.*\\)[ \n\t]+\\(:\\)\\(.*\\)\\(->\\)\\(.*\\)" .
         ((1 font-lock-function-name-face)
          (2 font-lock-keyword-face)
          (3 font-lock-type-face)
          (4 font-lock-keyword-face)
          (5 font-lock-type-face)
          ))
        ("-- .*" . font-lock-comment-face)
        )
      )

(define-derived-mode actorforth-mode fundamental-mode "actorforth"
  "Major mode for editing ActorForth files."
  (setq font-lock-defaults '(actorforth-highlights)))

;; override default colors for some
;; (set-face-foreground 'font-lock-doc-face        "Purple")
;; (set-face-foreground 'font-lock-comment-face    "LightGreen")

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.afth\\'" . actorforth-mode))


;;; actorforth-mode.el ends here

