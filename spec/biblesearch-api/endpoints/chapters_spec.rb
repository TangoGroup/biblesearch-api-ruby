require 'spec_helper'
require 'biblesearch-api'

describe BibleSearch do
  before do
    VCR.insert_cassette %{endpoint-#{File.basename(__FILE__, '.rb')}-#{__name__}}
    @biblesearch = BibleSearch.new('DUMMY_API_KEY')
  end

  after do
    VCR.eject_cassette
  end

  describe %{#chapters} do

    describe %{given a book signature} do
      describe %{as a string} do
        it %{raises an argument error for bad input} do
          bad_book_string = lambda { @biblesearch.chapters('SupDawg') }
          bad_book_string.must_raise ArgumentError
          (bad_book_string.call rescue $!).message.must_equal 'Book signature must be in the form "VERSION_ID:BOOK_ID"'
        end
      end

      describe %{as a hash} do
        before do
          @options = {
            :version_id => 'GNT',
            :book_id => '2Tim'
          }
        end

        describe %{if any pieces are missing} do
          it %{raises an argument error} do
            @options.keys.each do |key|
              options = @options
              options.delete(key)
              bad_book_hash = lambda { @biblesearch.chapters(options) }
              bad_book_hash.must_raise ArgumentError
              (bad_book_hash.call rescue $!).message.must_equal "Book signature hash must include :version_id and :book_id"
            end
          end
        end

        describe %{with a complete hash} do
          it %{returns the same thing as the equivalent string sig} do
            @biblesearch.chapters(@options).collection.must_equal @biblesearch.chapters('GNT:2Tim').collection
          end
        end
      end
    end

    describe %{when I make a valid request} do
      before do
        @chapters = @biblesearch.chapters('GNT:2Tim')
      end

      it %{has a collection} do
        @chapters.collection.must_be_instance_of Array
      end

      it %{should contain chapters} do
        @chapters.collection.length.must_be :>, 0
        @chapters.collection.each do |chapter|
          chapter.must_respond_to(:auditid)
          chapter.must_respond_to(:label)
          chapter.must_respond_to(:chapter)
          chapter.must_respond_to(:id)
          chapter.must_respond_to(:osis_end)
          chapter.must_respond_to(:parent)
          chapter.must_respond_to(:next)
          chapter.must_respond_to(:previous)
          chapter.must_respond_to(:copyright)
        end
      end
    end

    describe %{when I make a bad request} do
      before do
        @chapters = @biblesearch.chapters('GNT:Batman')
      end

      it %{has a collection} do
        @chapters.collection.must_be_instance_of Array
      end

      it %{contains no items} do
        @chapters.collection.length.must_equal 0
      end
    end
  end

  describe %{#chapter} do
    describe %{given a chapter signature} do
      describe %{as a string} do
        it %{raises an argument error for bad input} do
          bad_chapter_string = lambda { @biblesearch.chapter('SupDawg') }
          bad_chapter_string.must_raise ArgumentError
          (bad_chapter_string.call rescue $!).message.must_equal 'Chapter signature must be in the form "VERSION_ID:BOOK_ID.CHAPTER_NUMBER"'
        end
      end

      describe %{as a hash} do
        before do
          @options = {
            :version_id => 'GNT',
            :book_id => '2Tim',
            :chapter => 1
          }
        end

        describe %{if any pieces are missing} do
          it %{raises an argument error} do
            @options.keys.each do |key|
              options = @options
              options.delete(key)
              bad_chapter_hash = lambda { @biblesearch.chapter(options) }
              bad_chapter_hash.must_raise ArgumentError
              (bad_chapter_hash.call rescue $!).message.must_equal "Chapter signature hash must include :version_id, :book_id, and :chapter"
            end
          end
        end

        describe %{with a complete hash} do
          it %{returns the same thing as the equivalent string sig} do
            @biblesearch.chapter(@options).value.must_equal @biblesearch.chapter('GNT:2Tim.1').value
          end
        end
      end
    end

    describe %{when I make a valid request} do
      it %{has a chapter value} do
        @biblesearch.chapter('GNT:2Tim.1').value.tap do |chapter|
          chapter.must_respond_to(:auditid)
          chapter.must_respond_to(:label)
          chapter.must_respond_to(:chapter)
          chapter.must_respond_to(:id)
          chapter.must_respond_to(:osis_end)
          chapter.must_respond_to(:parent)
          chapter.must_respond_to(:next)
          chapter.must_respond_to(:previous)
          chapter.must_respond_to(:copyright)
        end
      end
    end

    describe %{when I request an invalid chapter} do
      it %{has a nil value} do
        @biblesearch.chapter('GNT:Batman.1').value.must_be_nil
      end
    end
  end
end
