# frozen_string_literal: true

require 'rails_helper'

RSpec.describe KGCL::IssueContentGenerator do
  it 'generates issue content for new synonym change requests' do
    params = {
      operation: KGCL::Operations::NEW_SYNONYM,
      curie: 'CL:0000209',
      concept_label: 'taste receptor cell',
      username: 'Daenerys Targaryen',
      create_synonym: { preferred_label: 'taste-bud cell', qualifier: 'exact', comment: 'Please add this!' }
    }

    title = "Proposal: add synonym 'taste-bud cell' for taste receptor cell"
    body = <<~HEREDOC.chomp
      ## Hey ontobot! apply:

      * create exact synonym 'taste-bud cell' for CL:0000209

      ---

      Comment: Please add this!

      This request comes from BioPortal user: Daenerys Targaryen
    HEREDOC

    content = KGCL::IssueContentGenerator.call(params)
    expect(content[:title]).to eq(title)
    expect(content[:body]).to eq(body)
  end

  it 'generates issue content for remove synonym change requests' do
    params = {
      operation: KGCL::Operations::REMOVE_SYNONYM,
      synonym: 'Gus deficiency',
      pref_label: 'mucopolysaccharidosis type 7',
      curie: 'MONDO:0009662',
      comment: "I don't think this is correct!",
      username: 'Sansa Stark'
    }

    title = 'Remove synonym "Gus deficiency" from mucopolysaccharidosis type 7 (MONDO:0009662)'
    body = <<~HEREDOC.chomp
      `remove synonym "Gus deficiency" from MONDO:0009662`

      Comment: I don't think this is correct!

      This request comes from BioPortal user: Sansa Stark
    HEREDOC

    content = KGCL::IssueContentGenerator.call(params)
    expect(content[:title]).to eq(title)
    expect(content[:body]).to eq(body)
  end

  it 'raises an error for invalid KGCL operations' do
    params = { operation: 'bogus operation' }
    msg = 'Invalid KGCL operation: bogus operation'
    expect { KGCL::IssueContentGenerator.call(params) }.to raise_error(ArgumentError, msg)
  end
end
