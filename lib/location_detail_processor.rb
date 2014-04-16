class LocationDetailProcessor
  def self.process_location_detail(content)
    fileparts = content.gsub("\r", "").split(/^---$/)

    fail "Required file section not found!" if fileparts[1].nil?

    eval fileparts[1].lines.to_a[2..-2].join

    total = instance_variables.reduce(0) { |sum, v| sum += instance_variable_get(v) }

    outputtable = "\n\nPosten | Wert\n"
    outputtable << " --- | ---:\n"
    instance_variables.each do |var|
      outputtable << "#{var.to_s.tr("@", "").capitalize} | #{instance_variable_get(var).to_s}\n"
    end
    outputtable << "**TOTAL** | **#{total}**\n\n"

    newfile = fileparts
    newfile[2] = outputtable

    newfile.join("---")
  end
end
