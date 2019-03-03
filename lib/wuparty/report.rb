class WuParty
  # Wraps an individual Wufoo Report.
  # == Instantiation
  # There are two ways to instantiate a Report object:
  # 1. Via the parent WuParty object that represents the account.
  # 2. Via the WuParty::Report class directly.
  #   wufoo = WuParty.new(ACCOUNT, API_KEY)
  #   report = wufoo.report(REPORT_ID)
  #   # or...
  #   report = WuParty::Report.new(REPORT_ID, :account => ACCOUNT, :api_key => API_KEY)
  # The first technique makes a call to the Wufoo API to get the report details,
  # while the second technique lazily loads the report details, once something is accessed via [].
  # == \Report Details
  # Access report details like it is a Hash, e.g.:
  #   report['Name']
  class Report < Entity
    # Access report details.
    def [](id)
      @details ||= @party.report(@id)
      @details[id]
    end

    # Returns field details for the report
    def fields
      @party.get("reports/#{@id}/fields")['Fields']
    end

    # Returns widget details for the report
    def widgets
      @party.get("reports/#{@id}/widgets")['Widgets']
    end
  end
end
