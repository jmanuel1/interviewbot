class WordExpressionParser

rule
  target: expression { print val[0] }

  expression: expression 'plus' expression
            | expression 'minus' expression
            | expression 'times' expression
            | expression 'divided' 'by' expression
            | number
  number: 'one' | 'two' | 'three' | 'four' | 'five' | 'six' | 'seven' | 'eight' | 'nine' { result = }

  def parse
    do_parse
  end

  def next_token
    @tokens.shift
  end

  def initialize expression
    @tokens = expression.split(' ').map { |token| [:word, token] }
  end
end