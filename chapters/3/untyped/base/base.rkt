#lang racket

(require "../types/types.rkt"
         "../Parse/parser.rkt"
         "../ExpValues/values-sig.rkt"
         "../ExpValues/values-unit.rkt"
         "../PrimitiveProc/primitive-proc-sig.rkt"
         "../PrimitiveProc/primitive-proc-unit.rkt"
         "../Procedure/proc-sig.rkt"
         "../Procedure/proc-unit.rkt"
         "../Environment/env-sig.rkt"
         "../Environment/env-unit.rkt"
         "../Expressions/exp-sig.rkt"
         "../Expressions/exp-unit.rkt")

(provide (all-from-out "../types/types.rkt")
         (except-out (all-defined-out)
                     unary-arithmetic-pred
                     unary-arithmetic-func
                     unary-IO-func

                     binary-equal-relation
                     binary-arithmetic-relation

                     n-ary-arithmetic-func
                     n-ary-logic-func

                     primitive-proc-table
                     add-primitive-proc!))


(define-compound-unit/infer base@
  (import)
  (export values^ env^ proc^ primitive-proc^ exp^)
  (link   values@ env@ proc@ primitive-proc@ exp@))

(define-values/invoke-unit base@
  (import)
  (export values^ env^ proc^ primitive-proc^ exp^))


(define-namespace-anchor ns-anchor)
(define eval-ns (namespace-anchor->namespace ns-anchor))

(define *eval*
  (λ (code env)
    (define exp
      (eval (parser code) eval-ns))

    ;; (pretty-print code)
    (value-of exp env)))


(define unary-arithmetic-pred
  (λ (pred)
    (λ vals
      (match vals
        [`(,val) (bool-val (pred (expval->num val)))]
        [_ (error 'unary-pred "Bad args: ~s" vals)]))))

(define unary-arithmetic-func
  (λ (func)
    (λ vals
      (match vals
        [`(,val) (num-val (func (expval->num val)))]
        [_ (error 'unary-func "Bad args: ~s" vals)]))))

(define unary-IO-func
  (λ (func)
    (λ vals
      (match vals
        [`(,val) (func (expval->s-expval val))]
        [_ (error 'unary-func "Bad args: ~s" vals)]))))


(define binary-equal-relation
  (λ (relation)
    (λ vals
      (match vals
        [`(,val-1 ,val-2)
         (bool-val (relation (expval->s-expval val-1)
                             (expval->s-expval val-2)))]
        [_ (error 'binary-relation "Bad args: ~s" vals)]))))


(define binary-arithmetic-relation
  (λ (relation)
    (λ vals
      (match vals
        [`(,val-1 ,val-2)
         (bool-val (relation (expval->num val-1)
                             (expval->num val-2)))]
        [_ (error 'binary-relation "Bad args: ~s" vals)]))))


(define n-ary-arithmetic-func
  (λ (func)
    (λ vals
      (match vals
        [`(,val-1 . ,(? list? vals))
         (num-val (apply func
                         (expval->num val-1)
                         (map (λ (val)
                                (expval->num val))
                              vals)))]
        [_ (error 'n-ary-arithmetic-func "Bad args: ~s" vals)]))))

(define n-ary-logic-func
  (λ (func)
    (λ vals
      (bool-val (apply func
                       (map (λ (val)
                              (expval->bool val))
                            vals))))))


(define add-primitive-proc!
  (λ (op-name op)
    (hash-set! primitive-proc-table op-name op)
    (base-env (extend-env op-name
                          (proc-val (procedure 'args
                                               (primitive-proc-exp 'apply-primitive
                                                                   (symbol-exp op-name)
                                                                   (var-exp 'args))
                                               (empty-env)))
                          (base-env)))))


(define all-true? (λ vals (andmap true? vals)))
(define all-false? (λ vals (ormap true? vals)))


(add-primitive-proc! 'empty-list (λ vals '()))


(add-primitive-proc! 'zero? (unary-arithmetic-pred zero?))
(add-primitive-proc! 'sub1 (unary-arithmetic-func sub1))
(add-primitive-proc! 'add1 (unary-arithmetic-func add1))
(add-primitive-proc! 'not (λ vals
                            (match vals
                              [`(,val) (bool-val (not (expval->bool val)))]
                              [_ (error 'unary-func "Bad args: ~s" vals)])))
(add-primitive-proc! 'car (λ vals
                            (match vals
                              [`(,val) (car (expval->pair val))]
                              [_ (error 'unary-func "Bad args: ~s" vals)])))
(add-primitive-proc! 'cdr (λ vals
                            (match vals
                              [`(,val) (cdr (expval->pair val))]
                              [_ (error 'unary-func "Bad args: ~s" vals)])))
(add-primitive-proc! 'null? (λ vals
                              (match vals
                                [`(,val) (bool-val (null? val))]
                                [_ (error 'unary-func "Bad args: ~s" vals)])))

(add-primitive-proc! 'display (unary-IO-func display))
(add-primitive-proc! 'print (unary-IO-func print))
(add-primitive-proc! 'write (unary-IO-func write))

(add-primitive-proc! 'displayln (unary-IO-func displayln))
(add-primitive-proc! 'println (unary-IO-func println))
(add-primitive-proc! 'writeln (unary-IO-func writeln))


(add-primitive-proc! '=  (binary-arithmetic-relation =))
(add-primitive-proc! '>  (binary-arithmetic-relation >))
(add-primitive-proc! '>= (binary-arithmetic-relation >=))
(add-primitive-proc! '<  (binary-arithmetic-relation <))
(add-primitive-proc! '<= (binary-arithmetic-relation <=))

(add-primitive-proc! 'eq?    (binary-equal-relation eq?))
(add-primitive-proc! 'eqv?   (binary-equal-relation eqv?))
(add-primitive-proc! 'equal? (binary-equal-relation equal?))


(add-primitive-proc! 'cons (λ vals
                             (match vals
                               [`(,val-1 ,val-2) (pair-val (cons val-1 val-2))]
                               [_ (error 'binary-func "Bad args: ~s" vals)])))

(add-primitive-proc! 'apply-primitive (λ vals
                                        (match vals
                                          [`(,(? symbol? val-1) ,(? list? val-2))
                                           (apply (hash-ref primitive-proc-table val-1) val-2)]
                                          [_ (error 'binary-func "Bad args: ~s" vals)])))


(add-primitive-proc! '+ (n-ary-arithmetic-func +))
(add-primitive-proc! '- (n-ary-arithmetic-func -))
(add-primitive-proc! '* (n-ary-arithmetic-func *))
(add-primitive-proc! '/ (n-ary-arithmetic-func /))

(add-primitive-proc! 'and (n-ary-logic-func all-true?))
(add-primitive-proc! 'or  (n-ary-logic-func all-false?))

(add-primitive-proc! 'list (λ vals (list-val vals)))



(base-env (extend-env 'apply
                      (proc-val (procedure '(func args)
                                           (call-exp (var-exp 'func)
                                                     (var-exp 'args))
                                           (empty-env)))
                      (base-env)))

(base-env (extend-env 'Y
                      (*eval* '(λ (f)
                                 ((λ (recur-func)
                                    (recur-func recur-func))
                                  (λ (recur-func)
                                    (f (λ args
                                         (apply (recur-func recur-func) args))))))
                              (base-env))
                      (base-env)))

(base-env (extend-env 'map
                      (*eval* '(Y (λ (map)
                                    (λ (func ls)
                                      (if (null? ls)
                                          '()
                                          (cons (func (car ls))
                                                (map func (cdr ls)))))))
                              (base-env))
                      (base-env)))

(base-env (extend-env 'Y*
                      (*eval* '(λ funcs
                                 ((λ (recur-funcs)
                                    (recur-funcs recur-funcs))
                                  (λ (recur-funcs)
                                    (map (λ (func)
                                           (λ args
                                             (apply (apply func (recur-funcs recur-funcs)) args)))
                                         funcs))))
                              (base-env))
                      (base-env)))