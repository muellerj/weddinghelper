class Symbol
  def humanize
    to_s.tr("@", "").capitalize
  end
end

class LocationDetailProcessor
  def self.moneyvars
    instance_variables.select { |v| instance_variable_get(v).class == Fixnum }
  end

  def self.total
    moneyvars.reduce(0) { |sum, v| sum += instance_variable_get(v) }
  end

  def self.summarytable
    table = "\n\nPosten | Wert\n"
    table << " --- | ---:\n"
    moneyvars.each do |var|
      table << "#{var.humanize} | #{instance_variable_get(var).to_s}\n"
    end
    table << "**TOTAL** | **#{total}**\n\n"
  end

  def self.call(content)
    fileparts = content.gsub("\r", "").split(/^---$/)

    fail "Required file section not found!" if fileparts[1].nil?

    eval fileparts[1].lines.to_a[2..-2].join

    fileparts[2] = summarytable

    fileparts.join("---")
  end

  def self.template
    <<-EOT.gsub(/^ {6}/, '')
      # Template location

      \`\`\`address
      \`\`\`

      ---
      \`\`\`ruby
      \`\`\`
      ---

      Posten | Wert
      --- | ---:
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
      subject.call(template) == template
    end

    it "shows instance variables, but not local variables" do
      subject.call(template.insert(49, "@foo = 100\nbar = 20\n")).tap do |content|
        content.must_match /Foo \| 100/
        content.wont_match /Bar \| 20/
      end
    end

    it "can handle non-Fixnum instance variables" do
      subject.call(template.insert(49, "@foo = :bar\n")).tap do |content|
        content.wont_match /Foo/
      end
    end

    it "correctly sums up all subtotals" do
      subject.call(template.insert(49, "@foo = 100\n@bar = 20\n")).tap do |content|
        content.must_match /\*\*TOTAL\*\* \| \*\*120\*\*/
      end
    end

  end

end
