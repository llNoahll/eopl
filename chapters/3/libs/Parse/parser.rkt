#lang typed/racket

(require "../types/types.rkt")

(provide (all-defined-out))


(: parser [-> S-Exp S-Exp])
(define parser
  (λ (code)
    (match code
      [`(quote ,(? symbol? symbol)) `(symbol-exp ',symbol)]
      [(? boolean? bool) `(bool-exp ,bool)]
      [(? integer? num) `(const-exp ,num)]

      [(? symbol? var) `(var-exp ',var)]

      [`(if ,(? s-exp? pred-exp)
            ,(? s-exp? true-exp)
            ,(? s-exp? false-exp))
       `(if-exp ,(parser pred-exp)
                ,(parser true-exp)
                ,(parser false-exp))]
      [`(cond [,(? s-exp?  #{pred-exps : S-List})
               ,(? s-list? #{body-exps : S-List})]
              ...)
       `(cond-exp
         (list ,@(map (λ ([pred-exp : S-Exp] [body-exp : S-Exp])
                        `(list ,(parser (if (eq? pred-exp 'else)
                                            #t
                                            pred-exp))
                               ,(parser body-exp)))
                      pred-exps
                      body-exps)))]
      [`(let ([,(? symbol? #{bound-vars : (Listof Symbol)})
               ,(? s-exp?  #{bound-exps : S-List})]
              ...)
          ,(? s-exp? body-exp))
       `(let-exp ',bound-vars
                 (list ,@(map parser bound-exps))
                 ,(parser body-exp))]
      [`(let* ([,(? symbol? #{bound-vars : (Listof Symbol)})
                ,(? s-exp?  #{bound-exps : S-List})]
               ...)
          ,(? s-exp? body-exp))
       (if (and (null? bound-vars) (null? bound-exps))
           `(let-exp '() '() ,(parser body-exp))
           (parser
            `(let ([,(car bound-vars) ,(car bound-exps)])
               (let* (,@(map (λ ([var : Symbol] [exp : S-Exp]) : (List Symbol S-Exp)
                                 (list var exp))
                             (cdr bound-vars)
                             (cdr bound-exps)))
                 ,body-exp))))]

      ;; [`(,(? s-exp? op) ,(? s-exp? #{exps : S-List}) ...)
      ;;  `(primitive-proc-exp ',op
      ;;                       ,@(map parser exps))]

      [`(,(? lambda?) (,(? symbol? #{args : (Listof Symbol)}) ...)
          ,(? s-exp? body-exp))
       `(proc-exp ',args ,(parser body-exp))]
      [`(,(? s-exp? op) ,(? s-exp? #{exps : S-List}) ...)
       `(call-exp ,(parser op)
                  (list ,@(map parser exps)))]
      )))