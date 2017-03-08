class ApplyWhitelistFilterToPayload
  def call(whitelist, payload)
    filter_hash(whitelist, payload)
  end

  private

  def filter_hash(whitelist, hash)
    hash.each do |k, v|
      unless whitelist && (whitelist[k] || whitelist[k.to_sym])
        hash[k] = '[FILTERED]'
      end

      if v.is_a?(Hash) && whitelist[k].is_a?(Hash)
        filter_hash(whitelist[k], v)
      end
    end
  end
end