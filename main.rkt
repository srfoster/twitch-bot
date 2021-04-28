#lang racket

;TODO:
;  * Make with-twitch-id actually safe
;  * Remove oauth creds from node-bot
;  * Tie into unreal/codespells
;  * Docs!  Tutorial video?

(require web-server/servlet-env
         web-server/http/json
         web-server/http/bindings
         json
         racket/sandbox
         racket/runtime-path
         )

(provide start-twitch-bot
         handle-twitch-message
         use-evaluator
         make-safe-evaluator
         current-twitch-id
         )

(define current-twitch-id (make-parameter #f))
(define (handle-twitch-message interpret)

  (define (extract-spell r)
    (extract-binding/single
     'spell
     (request-bindings r)))

  (define (extract-twitch-id r)
    (extract-binding/single
     'twitch-id
     (request-bindings r)))
  
  (lambda(r)
    (define spell (extract-spell r))
    (define twitch-id (extract-twitch-id r))
    
    (parameterize ([current-twitch-id twitch-id])
      (define val
        (interpret (read (open-input-string spell))))
      (define val-trimmed
        (if (> (string-length (~a val)) 200)
          (substring (~a val) 0 200)
          (~a val)))

      (response/jsexpr	
       (hasheq 'value
               (string-append "> @" (current-twitch-id) " " (~a val-trimmed)
                              )
               ;"> Thanks for the message!"
               )))))


(define safe-ns #f)



(module+ test
  (require rackunit)
  (define e
    (make-safe-evaluator 'twitch-bot/sample-chat))

  (check-equal?
   "Hello World"
   (e '(test)))

  (check-equal?
   "Fail is good"
   (with-handlers ([exn:fail?
                    (thunk* "Fail is good")])
       (e '(displayln "HI"))))
  )

(define (make-safe-evaluator lang)
  (displayln "Defining safe-evaluator...")
  (parameterize ([current-namespace
                  (make-base-empty-namespace)])
    (namespace-require lang)
    (set! safe-ns (current-namespace)))
  (displayln "Ending safe-evaluator def...")
   
  (lambda (expr)
    (displayln "Start eval...")
    (define ret (eval expr safe-ns))
    (displayln "End eval...")
    ret))

(define (use-evaluator evaluator)
  (lambda (s-expr)
    (evaluator
     `(with-twitch-id ,(current-twitch-id)
        ,s-expr))))

(define-runtime-path
  node-bot-directory "node-bot")

(define (start-twitch-bot [fn
                           (handle-twitch-message
                            (use-evaluator
                             (make-safe-evaluator
                              'twitch-bot/sample-chat)))])
  (thread
   (thunk
    (system (~a " cd " node-bot-directory " && yarn start"))))
  
  (serve/servlet fn
                 #:port 8081
                 #:servlet-regexp #rx""
                 #:launch-browser? #f
                 #:stateless? #t))

