class WuParty
  # Wraps an individual Wufoo User.
  class User < Entity
    # Access user details.
    def [](id)
      @details ||= @party.report(@id)
      @details[id]
    end
  end
end
