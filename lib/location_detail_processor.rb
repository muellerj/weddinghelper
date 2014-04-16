class Symbol
  def humanize
    to_s.tr("@", "").capitalize
  end
end

class LocationDetailProcessor
  def moneyvars
    instance_variables.select { |v| instance_variable_get(v).class == Fixnum }
  end

  def total
    moneyvars.reduce(0) { |sum, v| sum += instance_variable_get(v) }
  end

  def keylength
    (moneyvars.map(&:humanize).max { |a, b| a.length <=> b.length } || "**TOTAL**").length
  end

  def vallength
    (moneyvars.map { |v| instance_variable_get(v).to_s }.max { |a, b| a.length <=> b.length } || "**0**").length
  end

  def formatstring
    "%-#{keylength}s | %+#{vallength}s\n"
  end

  def summarytable
    table = "\n\n"
    table << (formatstring % ["Posten", "Wert"])
    table << (formatstring % ["---", "---:"])
    table << moneyvars.map { |var| formatstring % [var.humanize, instance_variable_get(var)] }.join
    table << "**TOTAL** | **#{total}**\n\n"
    table
  end

  def codeblock
    @fileparts[1].scan(/\`\`\`ruby\n(.*?)\`\`\`/m).flatten.first
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

      \`\`\`address
      Dudehome
      Sample street 123
      12345 Someplace
      Tel. 123 / 45678901
      \`\`\`

      ---
      \`\`\`ruby
      # Add your code for calculations here. All instance variables
      # appear in the total.
      \`\`\`
      ---

      Posten    |  Wert
      ---       |  ---:
      **TOTAL** | **0**

      ---

      [Zurueck zur Liste der Locations](../locationlist.markdown)
    EOT
  end

end


if __FILE__ == $0
  require "minitest/autorun"
  require "minitest/pride"

  describe LocationDetailProcessor do

    subject { LocationDetailProcessor }

    let(:template) { subject.template }

    it "processes the template without change" do
      subject.new(template).call.must_equal template
    end

    it "shows instance variables, but not local variables" do
      subject.new(template.insert(197, "@foo = 100\nbar = 20\n")).call.tap do |content|
        content.must_match /Foo \| 100/
        content.wont_match /Bar \| 20/
      end
    end

    it "can handle non-Fixnum instance variables" do
      subject.new(template.insert(197, "@foo = :bar\n")).call.tap do |content|
        content.wont_match /Foo/
      end
    end

    it "outputs nicely formatted tables" do
      subject.new(template.insert(197, "@foooooooooo = 100\n@bar = 20\n")).call.tap do |content|
        content.must_match /Foooooooooo \| 100/
        content.must_match /Bar         \|  20/
      end
    end

    it "correctly sums up all subtotals" do
      subject.new(template.insert(197, "@foo = 100\n@bar = 20\n")).call.tap do |content|
        content.must_match /\*\*TOTAL\*\* \| \*\*120\*\*/
      end
    end

    it "handles syntax errors gracefully" do
      subject.new(template.insert(197, "foo\n")).call.tap do |content|
        content.must_match /NameError/
        content.must_match /undefined local variable or method \`foo'/
      end
    end

  end

end
