module Raygun
  module Services
    class ApplyWhitelistFilterToPayload
      def call(whitelist, payload)
        filter_hash(whitelist, payload)
      end

      private

      def filter_hash(whitelist, hash)
        # dup the input so each level of the hash is dup'd
        # not just the top as dup isn't deep
        hash = hash.dup

        hash.each do |k, v|
          unless whitelist && (whitelist[k] || whitelist[k.to_sym])
            hash[k] = '[FILTERED]'
          end

          if v.is_a?(Hash) && whitelist[k].is_a?(Hash)
            hash[k] = filter_hash(whitelist[k], v)
          end
        end
      end
    end
  end
end
