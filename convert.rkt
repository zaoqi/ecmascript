#lang racket/base

(require (only-in racket/class
                  instantiate
                  object-method-arity-includes?
                  send)
         racket/math
         racket/string
         "object.rkt"
         "private/builtin.rkt"
         "private/error.rkt"
         "private/object.rkt")

(provide (all-defined-out))

(define (to-primitive v [hint 'number])
  (if (object? v)
      (let/ec return
        (for ([method (if (eq? 'string hint)
                          '("toString" "valueOf")
                          '("valueOf" "toString"))])
          (let ([f (get-property-value v method)])
            (when (and (object? f)
                       (object-method-arity-includes? f 'call 1))
              (let ([v (send f call v)])
                (unless (object? v)
                  (return v))))))
        (raise-native-error 'type))
      v))

(define (to-boolean v)
  (cond
    [(eq? v 'undefined) #f]
    [(eq? v 'null) #f]
    [(boolean? v) v]
    [(number? v) (not (or (zero? v) (nan? v)))]
    [(string? v) (not (string=? v ""))]
    [(object? v) #t]))

(define (to-number v)
  (cond
    [(eq? v 'undefined) +nan.0]
    [(eq? v 'null) 0]
    [(boolean? v) (if v 1 0)]
    [(number? v) v]
    [(string? v) (or (string->number (string-trim v)) +nan.0)]
    [(object? v) (to-number (to-primitive v 'number))]))

(define (to-integer v)
  (let ([v (to-number v)])
    (if (nan? v)
        0
        (truncate v))))

(define (to-int32 v)
  (let ([v (to-uint32 v)])
    (if (>= v (expt 2 31))
        (- v (expt 2 32))
        v)))

(define (to-uint32 v)
  (let ([v (to-integer v)])
    (if (or (nan? v) (infinite? v))
        0
        (inexact->exact
         (modulo v (expt 2 32))))))

(define (to-uint16 v)
  (let ([v (to-integer v)])
    (if (or (nan? v) (infinite? v))
        0
        (inexact->exact
         (modulo v (expt 2 16))))))

(define (to-string v)
  (cond
    [(eq? v 'undefined) "undefined"]
    [(eq? v 'null) "null"]
    [(boolean? v) (if v "true" "false")]
    [(number? v)
     (cond
       [(nan? v) "NaN"]
       [(infinite? v) "Infinity"]
       [else (number->string v)])]
    [(string? v) v]
    [(object? v) (to-string (to-primitive v 'string))]))

(define (to-object v)
  (cond
    [(eq? v 'undefined) (raise-native-error 'type "undefined")]
    [(eq? v 'null) (raise-native-error 'type "null")]
    [(boolean? v) (instantiate boolean% (v) [prototype boolean:prototype])]
    [(number? v) (instantiate number% (v) [prototype number:prototype])]
    [(string? v) (instantiate string% (v) [prototype string:prototype])]
    [(object? v) v]))