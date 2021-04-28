#lang racket

(provide #%module-begin
         #%top-interaction
         #%app
         #%datum

         ;Do not provide current-twitch-id if this
         ;  is a lang to be evalled!
         ;The setter is too dangerous.  Alows impersonation.
         
         with-twitch-id ;This is written to be safe, though.
         advanced-magic
         test
         )

(define current-twitch-id (make-parameter #f))

(define-syntax-rule (with-twitch-id id lines ...)
  (parameterize ([current-twitch-id id])
    lines ...))

(define (test [s "Hello World"])
  s)

(define (advanced-magic [s "Hello World"])
  (when (not (string=? "codespells"
                       (current-twitch-id)))
    (error "Only @codespells knows that spell"))
  
  "Wow! OhMyDog Much advanced!")