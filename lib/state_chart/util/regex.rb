# frozen_string_literal: true

module StateChart

  module Util

    module Regex

      # See https://www.w3.org/TR/xml/ for ID, IDREF, IDREFS, NMTOKEN definitions
      module XML

        NameStartChar = (
          "[%s]" % %W[
            _
            :
            A-Z
            a-z
            \u{C0}-\u{D6}
            \u{F8}-\u02FF
            \u0370-\u037D
            \u037F-\u1FFF
            \u200C-\u200D
            \u2070-\u218F
            \u2C00-\u2FEF
            \u3001-\uD7FF
            \uF900-\uFDCF
            \uFDF0-\uFFFD
            \u{10000}-\u{EFFFF}
          ].join
        ).freeze

        NameChar = (
          "[%s]" % %W[
            -
            .
            0-9
            #{NameStartChar}
            \u{B7}
            \u0300-\u036F
            \u203F-\u2040
          ].join
        ).freeze

        # Used to lexically validate {ID} or {IDREF} strings
        Name  = /#{NameStartChar}#{NameChar}*/

        # Exclusive match for {Name}
        NAME  = /\A#{Name}\z/

        # Used to lexically validate {IDREFS} strings.
        #
        # n.b. we are more lenient with '\s+' instead of '\x20' in the XML spec.
        # That allows us to skip the xsd:token normalization step.
        Names = /#{Name}(?:\s+#{Name})*/

        # Exclusive match for {Names}
        NAMES = /\A#{Names}\z/

        Id = Name
        IdRef = Name
        IdRefs = Names

        # ID is used by {State#id}, {Data::Attribute#id}, {Actions::Send#id}
        ID = NAME

        # IDREF is used by {Actions::Cancel#send_id}.
        IDREF = NAME

        # Used by {Chart#initial}, {State::Compound#initial}, {Transition#target}
        IDREFS = NAMES

        # Used by {Chart#name}, {Actions::Raise#event}, {Param#name}
        NmToken = /#{NameChar}+/

        # Exclusive match for {NmToken}
        NMTOKEN = /\A#{NmToken}\z/

        # n.b. we allow a more lenient '\s+' rather than only '\x20' in XML. That
        # allows us to skip the xsd:token normalization step.
        NmTokens = /#{NmToken}(?:\s+#{NmToken})*/

        # Exclusive match for {NmTokens}
        NMTOKENS = /\A#{NmTokens}\z/

      end

      # use in place of XSD's "\i" character class
      XMLi = XML::NameStartChar

      # use in place of XSD's "\c" character class
      XMLc = XML::NameChar

      # See https://www.w3.org/2011/04/SCXML/scxml-datatypes.xsd for SCXML types
      module SCXML

        # From SCXML schema definition:
        #
        # Duration allowing positive values ranging from milliseconds to days.
        #
        #     <xsd:restriction base="xsd:string">
        #       <xsd:pattern value="\d*(\.\d+)?(ms|s|m|h|d)"/>
        #     </xsd:restriction>
        DURATION = /\A(?<number>\d*(?:\.\d+))?(?<unit>ms|s|m|h|d)\z/

        # A single segment or token of an {EventName}.  Unlike {XML::Name},
        # there are no extra restrictions on the first char, but only dashes and
        # digits are added to the {XML::NameStartChar} chars.  Most notably: "."
        # is not allowed, because it is used as the delimiter.
        EventTok  = /[-\d#{XMLi}]+/

        # From SCXML schema definition:
        #
        # EventType is the name of an event. Example legal values: foo foo.bar
        # foo.bar.baz
        #
        #      <xsd:restriction base="xsd:token">
        #        <xsd:pattern value="(\i|\d|\-)+(\.(\i|\d|\-)+)*"/>
        #      </xsd:restriction>
        EventName = /#{EventTok}(?:\.#{EventTok})*/

        # Exclusive match for {EventName}
        EVENT_NAME  = /\A#{EventName}\z/

        # The wildcard suffix is implicit and optional.
        # It is included for backward compatibility with pre-SCXML schemas
        EventNameWithWildSuffix = /(?<base>#{EventName})(?:\.\*)?/

        EVENT_NAME_WITH_WILD_SUFFIX  = /\A#{EventNameWithWildSuffix}\z/

        WILDCARD   = /\A\.?\*\z/

        # From SCXML schema definition:
        #
        # Custom datatype for the event attribute in SCXML based on xsd:token.
        # Example legal values: * foo foo.bar foo.* foo.bar.* foo bar baz foo.bar
        # bar.* baz.foo.*
        #
        #      <xsd:restriction base="xsd:token">
        #        <xsd:pattern value="\.?\*|(\i|\d|\-)+(\.(\i|\d|\-)+)*(\.\*)?(\s(\i|\d|\-)+(\.(\i|\d|\-)+)*(\.\*)?)*"/>
        #      </xsd:restriction>
        EVENT_NAMES = Regexp.union(
          WILDCARD,
          /\A#{EventNameWithWildSuffix}(?:\s+#{EventNameWithWildSuffix})*\z/
        )

      end

      RubyKeywordList = %w[
        alias and BEGIN begin break case class def defined? do else elsif END
        end ensure false for if in module next nil not or redo rescue retry
        return self super then true undef unless until when while yield
      ]

      # use \b to matche only whole words, and not fragments inside words
      RubyKeyword = /\b#{Regexp.union(RubyKeywordList)}\b/

      # A valid ruby local variable name. We will also use it to validate
      # {DataModel} attribute names.
      #
      # @note This may not be perfectly aligned with ruby's parser, especially
      #       on older ruby versions.
      RubyLocalName = /\b(?!#{RubyKeyword}\z)[\p{Lower}_]\p{Word}*\b/

      # A valid ruby constant name.
      #
      # @note This may not be perfectly aligned with ruby's parser.
      RubyConstName = /\b(?!#{RubyKeyword}\z)\p{Upper}\p{Word}*\b/

      # A valid ruby constant path, including "::" path delimiters
      RubyConstPath = /(?:::)?#{RubyConstName}(?:::#{RubyConstName})*/

      # A name that should be safe for local variables or constants or methods
      #
      # Ruby does let us use many keywords as method names, but it's generally
      # easier to just avoid them anyway. We're also not allowing ruby's method
      # suffixes ("?", "!", or "=") here, because we may add those later
      # ourselves.
      #
      # Also note: this is different from both {XML::Name} and {XML::NmToken}.
      #
      # Used by {State#name}, and thus indirectly by many others.
      ValidName = /\b(?!#{RubyKeyword})\p{Alpha}\p{Word}*\b/

      # Exclusive match for {ValidName}
      VALID_NAME = /\A#{ValidName}\z/

      # valid predicate method names, including an optional "?" suffix
      #
      # It feels weird for capitalized predicates to be allowed... but they are!
      VALID_PREDICATE_NAME = /\A#{ValidName}[?]?\z/

      # valid method names, including "!" or "?" suffixes
      # ignoring "=" writer methods, because those are handled specially
      VALID_METHOD_NAME = /\A#{ValidName}[!?]?\z/

      # @note this is not the same as valid LHS or RHS expressions
      #
      # used by {VALID_ID} to validate state paths
      DottedNamePath  = /#{ValidName}(?:\.#{ValidName})*/

      ValidId = /#{Regexp.union(DottedNamePath, XML::Id)}/
      VALID_ID = /\A#{ValidId}\z/

      ValidIds = /#{ValidId}(?:\s+#{ValidId})*/
      VALID_IDS = /\A#{ValidIds}\z/

      IdWithPrefix = /\#?#{ValidId}/

      SlashAncestor = %r{\.\.(?:/\.\.)*}
      DottedAncestor = /\.\.+/
      Ancestor = Regexp.union(SlashAncestor, DottedAncestor)
      ANCESTOR_REF = /\A#{Ancestor}\z/

      SelfOrSlashAncestor = Regexp.union(SlashAncestor, ".")
      SlashDelimitedPath = %r{#{SelfOrSlashAncestor}?/#{ValidName}(?:/#{ValidName})*}
      SLASH_DELIMITED_PATH = /\A#{SlashDelimitedPath}\z/

      DotDelimitedPath = /\.*#{DottedNamePath}/
      DOT_DELIMITED_PATH = /\A#{DotDelimitedPath}\z/
      DOT_DELIMITED_SCAN = /\A\.+|#{ValidName}/

      ValidRef = Regexp.union(
        IdWithPrefix,
        DotDelimitedPath,
        SlashDelimitedPath,
        SlashAncestor,
        DottedAncestor,
        "."
      )

      VALID_REF = /\A#{ValidRef}\z/

      ValidRefs = /#{ValidRef}(?:\s+#{ValidRef})*/
      VALID_REFS = /\A#{ValidRefs}\z/

    end
  end
end
