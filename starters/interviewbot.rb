#
# Ruby automated interviewbot example
#
# Can you write a program that passes the interviewbot test?
#
require "net/http"
require "json"
require "prime"

def main
  # get started
  # get the path to the first question
  start_result = post_json('/interviewbot/start', { :login => 'jmanuel1'})
  question_path = start_result['nextQuestion']

  loop do
  # Answer each question
    # get the next question
    question = get_json(question_path)

    # your code to figure out the answer goes here
    answer = answer_question(question)

    # send it to interviewbot
    answer_result = send_answer(question_path, answer)

    break if answer_result['result'] != 'correct'
    question_path = answer_result['nextQuestion']
  end
end

def answer_question(question)
  # NOTE: This assumes the question is of the form "Find the prime factors of the number {{number}}. ..."
  number = question['question']
  problem = question['message']
  return find_prime_factors_of number if
    problem.start_with? 'Find the prime factors of the number'
  return roman_number_to_number number if
    problem.start_with? 'Please convert this roman numeral to a number:'
  return evaluate_word_expression number if
    problem.start_with? 'Please compute the numeric value of'
  raise "I don't understand!"
end

def evaluate_word_expression(expression)
  tokens = expression.split(' ')
  first_term = evaluate_word_term(tokens)
  if tokens.length == 0 then
    return first_term
  else
    operator = tokens.shift
    if operator == 'add' then
      return first_term + evaluate_word_term(tokens)
    elsif operator == 'minus' then
      return first_term + evaluate_word_term(tokens)
    end
  end
end

def evaluate_word_term(tokens)
  left = evaluate_number(tokens)
  if tokens.length == 0 or not ['times', 'divided'].include?(tokens[0]) then
    return left
  end
  operator = tokens.shift
  if operator == 'times' then
    return left * evaluate_word_term(tokens)
  end
  if operator == 'divided' then
    tokens.shift
    return left / evaluate_word_term(tokens)
  end
end

def evaluate_number(tokens)
  digits = { 'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5, 'six': 6, 'seven': 7, 'eight': 8, 'nine': 9}
  digits[tokens.shift]
end

def roman_number_to_number numeral
  letter_map = {
    'i' => 1,
    'v' => 5,
    'x' => 10,
    'l' => 50,
    'c' => 100,
    'd' => 500,
    'm' => 1000
  }
  numeral.downcase.each_char.chunk { |letter| letter }
  .reduce({ :number => 0, :previous => nil }) { |memo, chunk|
    letter = chunk[0]
    length = chunk[1].length
    if memo[:previous] == nil then
      next memo.merge({
        :previous => letter,
        :number => letter_map[letter]*length
      })
    elsif letter_map[memo[:previous]] > letter_map[letter] then
      next memo.merge({
        :previous => letter,
        :number => memo[:number] + letter_map[letter]*length
      })
    else
      # assume there was only one of the previous letter
      number = memo[:number] - letter_map[memo[:previous]]*2 + letter_map[letter]
      next memo.merge({ :previous => letter, :number => number })
    end
  }[:number]
end

def remove_period_from(dirty_number)
  dirty_number[0..-2]
end

def find_prime_factors_of(number)
  Prime.prime_division(number, Prime::EratosthenesGenerator.new).map { |pair| pair[0] }
end

def send_answer(path, answer)
  post_json(path, { :answer => answer })
end

# get data from the api and parse it into a ruby hash
def get_json(path)
  puts "*** GET #{path}"

  response = Net::HTTP.get_response(build_uri(path))
  result = JSON.parse(response.body)
  puts "HTTP #{response.code}"

  puts JSON.pretty_generate(result)
  result
end

# post an answer to the noops api
def post_json(path, body)
  uri = build_uri(path)
  puts "*** POST #{path}"
  puts JSON.pretty_generate(body)

  post_request = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
  post_request.body = JSON.generate(body)

  response = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true) do |http|
    http.request(post_request)
  end

  puts "HTTP #{response.code}"
  result = JSON.parse(response.body)
  puts JSON.pretty_generate(result)
  result
end

def build_uri(path)
  domain = "https://api.noopschallenge.com"
  URI.parse(domain + path)
end

main()
