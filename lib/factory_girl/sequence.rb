class Factory

  # Raised when calling Factory.sequence from a dynamic attribute block
  class SequenceAbuseError < StandardError; end

  # Sequences are defined using Factory.sequence. Sequence values are generated
  # using next.  Calling reset rewinds to the beginning (for both the infinite
  # value counter and the enumeration if provided).
  class Sequence

    def initialize (enum = nil, &proc) #:nodoc:
      @enum = enum.to_a if !enum.nil?
      @enum_idx = 0
      @proc  = proc
      @value = 0
    end

    # Returns the next value for this sequence
    def next
      @value += 1
      retval = case @proc.arity
        when 1
          @enum ? @proc.call(@enum[@enum_idx]) : @proc.call(@value) 
        when 2
          @proc.call(@enum[@enum_idx], @value)
      end
      if @enum
        @enum_idx = (@enum_idx+1 == @enum.size) ? 0 : @enum_idx+1
      end
      retval
    end

    def reset
      @value = 0
      @enum_idx = 0
    end

  end

  class << self
    attr_accessor :sequences #:nodoc:
  end
  self.sequences = {}

  # Defines a new sequence that can be used to generate unique values in a specific format.
  #
  # Arguments:
  #   name: (Symbol)
  #     A unique name for this sequence. This name will be referenced when
  #     calling next to generate new values from this sequence.
  #   enum: (Array or Range)
  #     A delineated list of items (usually strings) to cycle through instead
  #     of, or in addition to, the normal infinite counter.
  #   block: (Proc)
  #     The code to generate each value in the sequence. This block will be
  #     called with a unique number each time a value in the sequence is to be
  #     generated. The block should return the generated value for the
  #     sequence.
  #
  # Example:
  #   
  #   Factory.sequence(:email) {|n| "somebody_#{n}@example.com" }
  def self.sequence (name, enum = nil, &block)
    self.sequences[name] = Sequence.new(enum, &block)
  end

  # Generates and returns the next value in a sequence.
  #
  # Arguments:
  #   name: (Symbol)
  #     The name of the sequence that a value should be generated for.
  #
  # Returns:
  #   The next value in the sequence. (Object)
  def self.next (sequence)
    unless self.sequences.key?(sequence)
      raise "No such sequence: #{sequence}"
    end

    self.sequences[sequence].next
  end

  # Resets a sequence to the beginning for both the infinite value counter and
  # the delineated enumeration if provided.
  def self.reset (name)
    self.sequences[name].reset
  end
end
