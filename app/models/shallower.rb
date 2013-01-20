# 入力されたリストから同じディレクトリ部分だけをすべて取り除いたリストを返す
# see. spec file
class Shallower
  def shallow(paths)
    deepest_dirs = nil
    paths.each do |path|
      ls = path.rindex '/'
      return paths unless ls # if no slash found, they seem to be flat entirely.
      dir = path[0, ls]
      deepest_dirs = match_dir(deepest_dirs, dir)
      return paths if deepest_dirs.empty?
    end
    deepest_path = deepest_dirs.join('/') + '/'
    paths.map do |path|
      path.gsub(/^#{deepest_path}/, '')
    end
  end
  private
  def match_dir(deepest_dirs, dir)
    dirs = dir.split('/')
    return dirs unless deepest_dirs
    return dirs if deepest_dirs == dirs
    match_dirs = []
    deepest_dirs.each_with_index do |dd, index|
      break unless dd == dirs[index]
      match_dirs << dd
    end
    match_dirs
  end
end
