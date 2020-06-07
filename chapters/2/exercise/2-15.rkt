#lang typed/racket


(require "../lambda-expression/typed-lambda-expression-version-2/lambda-expression-sig.rkt"
         "../lambda-expression/typed-lambda-expression-version-2/lambda-expression-unit.rkt"
         "../parser/typed-parse-unparse-version-1/parse-unparse-sig.rkt"
         "../parser/typed-parse-unparse-version-1/parse-unparse-unit.rkt")

(define-values/invoke-unit lambda-expression@
  (import)
  (export lambda-expression^))

(define-values/invoke-unit parse-unparse@
  (import lambda-expression^)
  (export parse-unparse^))


(: occurs-free? [-> Variable Lc-Exp Boolean])
(define occurs-free?
  (λ (search-var exp)
    (cond [(var-exp? exp)
           (eqv? search-var (var-exp->var exp))]
          [(lambda-exp? exp)
           (and (not (eqv? search-var
                           (var-exp->var (lambda-exp->bound-var exp))))
                (occurs-free? search-var (lambda-exp->body exp)))]
          [else (or (occurs-free? search-var (app-exp->rator exp))
                    (occurs-free? search-var (app-exp->rand  exp)))])))

(: occurs-free?-test [-> Variable Lc-Exp Void])
(define occurs-free?-test
  (λ (search-var exp)
    (displayln "--------------------------")
    (displayln search-var)
    (displayln exp)
    (displayln (occurs-free? search-var exp))
    (displayln "--------------------------")
    (newline)))

(var-exp (variable 'x))
(occurs-free?-test (variable 'x) (var-exp (variable 'x)))
(occurs-free?-test (variable 'x) (var-exp (variable 'y)))
(occurs-free?-test (variable 'x)
                   (lambda-exp (var-exp (variable 'x))
                               (app-exp (var-exp (variable 'x))
                                        (var-exp (variable 'y)))))
(occurs-free?-test (variable 'x)
                   (lambda-exp (var-exp (variable 'y))
                               (app-exp (var-exp (variable 'x))
                                        (var-exp (variable 'y)))))
(occurs-free?-test (variable 'x)
                   (app-exp (lambda-exp (var-exp (variable 'x))
                                        (var-exp (variable 'x)))
                            (app-exp (var-exp (variable 'x))
                                     (var-exp (variable 'y)))))
(occurs-free?-test (variable 'x)
                   (lambda-exp (var-exp (variable 'y))
                               (lambda-exp (var-exp (variable 'z))
                                           (app-exp (var-exp (variable 'x))
                                                    (app-exp (var-exp (variable 'y))
                                                             (var-exp (variable 'z)))))))

(unparse-lc-exp (lambda-exp (var-exp (variable 'y))
                            (lambda-exp (var-exp (variable 'z))
                                        (app-exp (var-exp (variable 'x))
                                                 (app-exp (var-exp (variable 'y))
                                                          (var-exp (variable 'z)))))))


(displayln (parse-expression '(λ (x) ((x x) (λ (z) (z x))))))
(displayln (unparse-lc-exp (parse-expression '(λ (x) ((x x) (λ (z) (z x)))))))