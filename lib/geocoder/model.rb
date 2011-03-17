require 'geocoder'

module Geocoder

  ##
  # Methods for invoking Geocoder in a model.
  #
  module Model
    module Base

      def geocoder_options
        @geocoder_options
      end

      private # ----------------------------------------------------------------

      def geocoder_init(options)
        unless geocoder_initialized?
          @geocoder_options = {}
          require "geocoder/orms/#{geocoder_file_name}"
          include eval("Geocoder::Orm::" + geocoder_module_name)
        end
        @geocoder_options.merge! options
      end

      def geocoder_initialized?
        begin
          included_modules.include? eval("Geocoder::Orm::" + geocoder_module_name)
        rescue NameError
          false
        end
      end
    end

    module ActiveRecord
      include Base

      ##
      # Set attribute names and include the Geocoder module.
      #
      def geocoded_by(address_attr, options = {}, &block)
        geocoder_init(
          :geocode       => true,
          :user_address  => address_attr,
          :latitude      => options[:latitude]  || :latitude,
          :longitude     => options[:longitude] || :longitude,
          :geocode_block => block
        )
      end

      ##
      # Set attribute names and include the Geocoder module.
      #
      def reverse_geocoded_by(latitude_attr, longitude_attr, options = {}, &block)
        geocoder_init(
          :reverse_geocode => true,
          :fetched_address => options[:address] || :address,
          :latitude        => latitude_attr,
          :longitude       => longitude_attr,
          :reverse_block   => block
        )
      end

      private
      def geocoder_file_name;   "active_record"; end
      def geocoder_module_name; "ActiveRecord"; end
    end

    module Mongoid
      include Base

      ##
      # Set attribute names and include the Geocoder module.
      #
      def geocoded_by(address_attr, options = {}, &block)
        geocoder_init(
          :geocode       => true,
          :user_address  => address_attr,
          :coordinates   => options[:coordinates] || :coordinates,
          :geocode_block => block
        )
      end

      ##
      # Set attribute names and include the Geocoder module.
      #
      def reverse_geocoded_by(coordinates_attr, options = {}, &block)
        geocoder_init(
          :reverse_geocode => true,
          :fetched_address => options[:address] || :address,
          :coordinates     => coordinates_attr,
          :reverse_block   => block
        )
      end

      def self.included(base); base.extend(self); end
      private
      def geocoder_file_name;   "mongoid"; end
      def geocoder_module_name; "Mongoid"; end

      def geocoder_init(options)
        super(options)

        # create 2d index
        index [[ geocoder_options[:coordinates], Mongo::GEO2D ]],
          :min => -180, :max => 180
      end
    end
  end
end