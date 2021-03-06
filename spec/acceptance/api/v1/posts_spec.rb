# frozen_string_literal: true

require 'spec_helper'

describe 'Posts API', type: :api do # rubocop:disable Metrics/BlockLength
  it 'sends the list of posts using the default filter' do
    user = User.create(username: 'Test User')

    posts = [
      Post.create(name: 'test', user: user),
      Post.create(name: 'test 2', user: user)
    ]

    get '/api/v1/posts'

    expect(last_response.status).to eq(200)
    expect(json.length).to eq(posts.count)
  end

  it 'is paging with page offset using default page size and restricting size' do
    40.times do
      Post.create(name: 'page item')
    end

    get '/api/v1/posts?page%5Boffset%5D=1'

    expect(json.length).to eq(25)
  end

  it 'is page offset of 2 working for size of 40 default page size of 25' do
    40.times do
      Post.create(name: 'page item')
    end

    get '/api/v1/posts?page%5Boffset%5D=2'

    expect(json.length).to eq(15)
  end

  it 'is page offset of -1 working for size of 40 default page size of 25' do
    # min page offset is 1, anything less gets converted to 1 and results in page size records
    40.times do
      Post.create(name: 'page item')
    end

    get '/api/v1/posts?page%5Boffset%5D=-1'

    expect(json.length).to eq(25)
  end

  it 'is page offset of 3 working for size of 40 default page size of 25' do
    # overflow on page offset will result in 0 records
    40.times do
      Post.create(name: 'page item')
    end

    get '/api/v1/posts?page%5Boffset%5D=3'

    expect(json.length).to eq(0)
  end

  it 'is page size of 10 working for default offset of 1' do
    # overflow on page offset will result in 0 records
    40.times do
      Post.create(name: 'page item')
    end

    get '/api/v1/posts?page%5Bsize%5D=10'

    expect(json.length).to eq(10)
  end

  it 'is page size working when the value is negative' do
    # overflow on page offset will result in 0 records
    40.times do
      Post.create(name: 'page item')
    end

    get '/api/v1/posts?page%5Bsize%5D=-10'

    expect(json.length).to eq(25)
  end

  it 'is page size working when the value is higher than the total record count' do
    # overflow on page offset will result in 0 records
    40.times do
      Post.create(name: 'page item')
    end

    get '/api/v1/posts?page%5Bsize%5D=100'

    expect(json.length).to eq(40)
  end

  it 'is the result all records when no page paramas are sent' do
    # overflow on page offset will result in 0 records
    100.times do
      Post.create(name: 'page item')
    end

    get '/api/v1/posts'

    expect(json.length).to eq(100)
  end

  it 'restricts page_size when max_per_page config is less' do
    100.times do
      Post.create(name: 'page item')
    end

    Kaminari.config.max_per_page = 10

    get '/api/v1/posts?page%5Bsize%5D=100'

    expect(json.length).to eq(10)
  end

  it 'sends posts filtered by ids' do
    all_posts = [
      Post.create(name: 'test'),
      Post.create(name: 'test 2'),
      Post.create(name: 'test 3')
    ]

    filtered_posts = [all_posts[0], all_posts[2]]

    get '/api/v1/posts?ids%5B%5D=' + filtered_posts[0].id.to_s +
        '&ids%5B%5D=' + filtered_posts[1].id.to_s

    expect(last_response.status).to eq(200)

    expect(json.length).to eq(filtered_posts.count)
  end

  it 'sends posts reverse sorted by id' do
    20.times do |i|
      Post.create(name: 'Post' + i.to_s)
    end

    get '/api/v1/posts?sort%5Bcriteria%5D=id&sort%5Breverse%5D=true'

    expect(json.last['posts']['name']).to eq('Post0')
  end

  it 'sends posts reverse sorted by id and paginated with a size of 10 and an offset of 1' do
    20.times do |i|
      Post.create(name: 'Post' + i.to_s)
    end

    get '/api/v1/posts?page%5Boffset%5D=1&page%5Bsize%5D=10&sort%5Bcriteria%5D=id&sort%5Breverse%5D=true' # rubocop:disable Metrics/LineLength

    expect(json.first['posts']['name']).to eq('Post19')
    expect(json.length).to eq(10)
  end

  it 'exports to csv' do
    post = Post.create(name: 'Post')

    get '/api/v1/posts.csv'

    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq("\n#{post.id},#{post.name}\n")
  end
end
