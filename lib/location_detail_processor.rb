#encoding: utf-8

class Symbol
  def humanize
    to_s.tr("@", "").capitalize
  end
end

class Fixnum
  def to_currency
    "%.2f" % self
  end
end

class Float
  def to_currency
    "%.2f" % self
  end
end

class LocationDetailProcessor
  def moneyvars
    vars = instance_variables.select { |v| [Fixnum, Float].include? instance_variable_get(v).class }
  end

  def total
    moneyvars.reduce(0) { |sum, v| sum += instance_variable_get(v) }
  end

  def keylength
    [(moneyvars.map(&:humanize).map(&:length).max || 0), "**TOTAL**".length].max
  end

  def vallength
    [(moneyvars.map { |v| instance_variable_get(v).to_currency }.map(&:length).max || 0), "**#{total.to_currency}".length].max
  end

  def formatstring
    "%-#{keylength}s | %+#{vallength}s\n"
  end

  def formatstring_total
    "%-#{keylength}s | %+#{[vallength, 6].max}s\n"
  end

  def summarytable
    table = "\n\n"
    table << (formatstring % ["Posten", "Wert"])
    table << (formatstring % ["---", "---:"])
    table << moneyvars.map { |var| formatstring % [var.humanize, instance_variable_get(var).to_currency] }.join
    table << (formatstring % ["**TOTAL**", "**#{total.to_currency}**"])
    table << "\n"
    table
  end

  def codeblock
    @fileparts[1][1..-1].gsub(/^ {4}/, "")
  end

  def guestcount
    count = {}
    statstr = `make statistics`
    count[:total] = statstr.scan(/Anzahl Gäste: (\d+)/).flatten.first.to_i
    count[:adults] = statstr.scan(/Erwachsene: (\d+)/).flatten.first.to_i
    count[:children] = statstr.scan(/Kinder: (\d+)/).flatten.first.to_i
    count[:babies] = statstr.scan(/Babies: (\d+)/).flatten.first.to_i
    count
  end

  def initialize(content)
    @fileparts = content.gsub("\r", "").split(/^---$/)
    fail "Required file section not found!" if @fileparts[1].nil?
  end

  def call
    eval codeblock
    @fileparts[2] = summarytable
    @fileparts.join("---")
  rescue Exception => exception
    exception.inspect
  end

  def self.template
    <<-EOT.gsub(/^ {6}/, '')
      # Template location

          Dudehome
          Sample street 123
          12345 Someplace
          Tel. 123 / 45678901

      ---
          # Add your code for calculations here. All instance variables
          # appear in the total.
      ---

      Posten    |   Wert
      ---       |   ---:
      **TOTAL** | **0.00**

      ---

      [Zurueck zur Liste der Locations](../locationlist.markdown)
    EOT
  end

end


if __FILE__ == $0
  require "minitest/autorun"
  require "minitest/pride"
  require "pry"

  describe LocationDetailProcessor do

    subject { LocationDetailProcessor }

    let(:template) { subject.template }

    it "processes the template without change" do
      subject.new(template).call.must_equal template
    end

    it "shows short instance variables, but not local variables" do
      subject.new(template.insert(198, "    @foo = 100\n    bar = 20\n")).call.tap do |content|
        content.must_include "Foo       |   100.00"
        content.wont_include "Bar"
        content.must_include "**TOTAL** | **100.00**"
      end
    end

    it "can handle non-Fixnum instance variables" do
      subject.new(template.insert(198, "    @foo = :bar\n")).call.tap do |content|
        content.wont_include "Foo"
        puts content
      end
    end

    it "outputs nicely formatted tables correctly summed" do
      subject.new(template.insert(198, "    @foooooooooo = 100.5\n@bar = 20\n")).call.tap do |content|
        content.must_include "Foooooooooo |   100.50"
        content.must_include "Bar         |    20.00"
        content.must_include "**TOTAL**   | **120.50**"
      end
    end

    it "handles syntax errors gracefully" do
      subject.new(template.insert(198, "    foo\n")).call.tap do |content|
        content.must_include "NameError"
        content.must_include "undefined local variable or method \`foo'"
      end
    end

  end

end
