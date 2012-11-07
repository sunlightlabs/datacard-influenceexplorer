module InfluenceExplorerMapping
  module ChoiceFields
    def filing_type_choices
      {
        n: "Non-self filer parent",
        m: "Non-self filer subsidiary for a non-self filer parent",
        x: "Self filer subsidiary for a non-self filer parent",
        p: "Self filer parent",
        i: "Non-self filer for a self filter parent that has same catorder as the parent",
        s: "Self filer subsidiary for a self filer parent",
        e: "Non-self filer subsidiary for a self filer subsidiary",
        c: "Non-self filer subsidiary for a self filer parent with same catorder",
        b: "Non-self filer subidiary for a self-filer parent that has different catorder"
      }
    end

    def crp_categories
      @@_crp_categories ||= CSV.parse(HTTParty.get("http://www.opensecrets.org/downloads/crp/CRP_Categories.txt").parsed_response.split("\r\n\r\n")[1], col_sep: "\t")
    end

    def ie_transaction_types
      @@_ie_transaction_types ||= []
      return Hash[@@_ie_transaction_types] if @@_ie_transaction_types.any?
      opts_str = HTTParty.get("http://assets.transparencydata.org.s3.amazonaws.com/docs/transaction_types-20100402.csv")
      opts = CSV.parse(opts_str)
      @@_ie_transaction_types = opts.collect do |row|
        row.collect{|v| v.gsub(/^?\|$?/, '')}
      end
      Hash[@@_ie_transaction_types]
    end

    def seats
      {
        "federal:senate" => "US Senate",
        "federal:house" => "US House of Representatives",
        "federal:president" => "US President",
        "state:upper" => "Upper chamber of state legislature",
        "state:lower" => "Lower chamber of state legislature",
        "state:governor" => "State governor"
      }
    end

    def parties
      {"D" => "Democrat", "R" => "Republican", "I" => "Independent"}
    end

    def election_cycles_since(year)
      values = {}
      (year..Time.now.year).step(2).to_a.each do |y|
        values[y.to_s] = "#{(y-1).to_s} - #{y.to_s}"
      end
      values
    end

    def format_number(num)
      num.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
    end
  end
end