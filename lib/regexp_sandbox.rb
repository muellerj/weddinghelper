class SyntaxChecker

  def initialize(code)
    @code = code
    @vars = []
  end

  def valid?
    @code.lines.all? { |line| line_valid?(line) }
  end

  def line_valid?(line)
    if %r{(@?\w+) = (?:\+?-?\d+(?:\.\d{2})?|#{@vars.join("|")})}.match(line)
      @vars << line.scan(%r{(@?\w+) =}).flatten.first
      return true
    else
      return false
    end
  end

end


if __FILE__ == $0
  require "minitest/autorun"
  require "minitest/pride"

  describe SyntaxChecker do

    it "allows simple local variable assignments" do
      SyntaxChecker.new("@local = 42").must_be :valid?
    end

    it "doesn't allow malicious stuff" do
      SyntaxChecker.new("system(\"rm -rf /\")").wont_be :valid?
    end

    it "allows the reuse of self-defined variables" do
      code = <<-EOS.gsub(/^ {8}/, '')
        @local = 42
        @foo = local + 2
      EOS
      SyntaxChecker.new(code).must_be :valid?
    end

  end
end
