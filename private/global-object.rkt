#lang racket/base

(require racket/class
         "object.rkt")

(provide global-object)

(define global-object
  (new ecma-object%
       [prototype #f]
       [class "Object"]))