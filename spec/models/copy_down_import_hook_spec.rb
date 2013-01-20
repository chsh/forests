require "spec_helper"

describe CopyDownImportHook do

  it "should can convert various rows" do
    rows = [
            ['a', nil, nil],
            [nil, 'b', nil],
            [nil, nil, 'c1a'],
            [nil, nil, 'c1b'],
            ['a2', 'b2', 'c2a'],
            [nil, nil, 'c2b'],
            [nil, 'b2a', nil],
    ]

    CopyDownImportHook.convert(rows).should == [
            ['a', nil, nil],
            ['a', 'b', nil],
            ['a', 'b', 'c1a'],
            ['a', 'b', 'c1b'],
            ['a2', 'b2', 'c2a'],
            ['a2', 'b2', 'c2b'],
            ['a2', 'b2a', nil],
            ]
  end
end
