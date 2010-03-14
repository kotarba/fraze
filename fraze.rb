#################################################
# Program FRAZE pro uceni frazi a slovicek
# Program FRAZE for learning phrases and words
#################################################
# Author: Josef Kotarba jkotarba_volny.cz
# Version: 2.0
# Timestamp: 2009-03-13
# Copyright: (C) 2009
######################################################################
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#######################################################################

WINDOWS = false  # pro Linux false, pro Windows true
KONVERZE = false # pro Windows true == cp1250->cp852 false == bez konverze

# trida Word pro ulozeni jmena import souboru, levelu, anglického a
# ceskeho vyrazu
class Word
  def initialize(fname,enlevel,czlevel,english,czech)
    @fname   = fname
    @enlevel  = enlevel
    @czlevel  = czlevel
    @english = english
    @czech   = czech
  end
  attr_reader :fname, :enlevel, :czlevel, :english, :czech
  attr_writer :fname, :enlevel, :czlevel, :english, :czech
# predani hodnoty levelu
  def level
    return ($en_cz == 'Y') ? @enlevel : @czlevel
  end
# predani prvniho slova, fraze
  def word1
    return ($en_cz == 'Y') ? @english : @czech
  end
# predani druheho slova, fraze
  def word2
    return ($en_cz == 'Y') ? @czech : @english
  end
# nastaveni levelu
  def setlevel(kod)
    if $en_cz == 'Y' then @enlevel = kod else @czlevel = kod end
  end
# zvetseni levelu o 1
  def addlevel(krok)
    if $en_cz == 'Y' then @enlevel += krok else @czlevel += krok end
  end
end

# vypis konfiguracnich parametru
def cfg_puts
  puts
  puts 'Y(eng->czech) N(czech->eng) ' + $en_cz
  puts 'filename or * for all       ' + $fname
  puts 'words level 0 ... n         ' + $level.to_s
  puts '1(random)/2(all new first)  ' + $alg.to_s
  puts
end

# wash_row - odstraneni poznamky, zruseni mezer, crlf a upcase
def wash_row(s)
    i = s.index(')')
    raise "line in file phrases.ini does not contain )" if i == nil
    return s.slice(i+1..-1).strip.upcase
    # slice vraci oznaceny substring
    # slice! vraci zbytek stringu
end

# nacteni konfiguracniho souboru
def cfg_read
  fd = File.new('fraze.ini', "r")
  $en_cz = wash_row(fd.readline)
  raise "character in 1.line fraze.ini is not Y/N" if $en_cz !~  /[YN]/
  $fname = wash_row(fd.readline)
  $level = Integer(wash_row(fd.readline))
  $alg = Integer(wash_row(fd.readline))
  fd.close()
end

# import slovicek a frazi z muse souboru
def import
  print 'Import filename: '
  $stdout.flush
  file = gets.chomp
  fd = File.new(file, "r")
  itecky = file.rindex('.')
  raise 'missing dot in filename' if itecky == nil
  fname = file[0,itecky]
  fname.upcase!
  puts
  fd.each do
    |row|
    if row.strip.length == 0 or row[0,1] == '*' or row[0,1] == '#'
      next
    end
    row.chomp!
    items = row.split          # deleni row na polozky oddelene mezerou
    nitems = items.length      # pocet polozek
    raise "only one word on the line\n[#{row}]" if nitems == 1
    if nitems == 2             # slovicka bez oddelovaci carky
      en = items[0]
      cz = items[1]
    else                       # slovicka a fraze s oddelovaci carkou
      i = row.index(' - ')     # oddelovac anglickeho a ceskeho vyrazu
      raise "missing ' - ' between English and Czech phrases\n[#{row}]" if i == nil
      en = row[0,i+1].strip    # prvni cast radku - anglicka
      cz = row[i+3..-1].strip  # druha cast radku - ceska
    end
    flag = false
    for iw in 0 ... $words.length do
      if $words[iw].fname == fname and
          ($words[iw].english == en or $words[iw].czech == cz) then
          flag = true
        break
      end
    end
    if flag == true then next end
    $words << Word.new(fname,0,0,en,cz)
    w = konverze($words.last.english + ' | ' + $words.last.czech)
    puts w
  end
  puts
  $stdout.flush
end

# zmena levelu pro kod = y,r,x
def change_level(kod,iw)
  case kod
  when 'y'       # povysit level
    $words[iw].addlevel(1)
  when 'r'       # reset level=0
    $words[iw].setlevel(0)
  when 'x'       # level +3
    $words[iw].addlevel(3)
  end
end

# zapis dat do souboru fraze.dat
def data_write
  fd = File.new('fraze.dat',"w")
  $words.each_index do
    |iw|
    printf(fd,"%s|%d|%d|%s|%s\n",
           $words[iw].fname,
           $words[iw].enlevel,
           $words[iw].czlevel,
           $words[iw].english,
           $words[iw].czech)
  end
  fd.close
  puts "\nDatabase stored"
end

# cteni souboru fraze.dat
def data_read
  fd = File.new('fraze.dat', "r")
  fd.each do
    |row|
    row.chomp!
    items = row.split('|')      # deleni row na polozky oddelene |
    raise "number of columns is not 5 \n[#{row}]" if items.length != 5
    $words << Word.new(items[0],items[1].to_i,items[2].to_i,items[3],items[4])
  end
  fd.close()
end

#zamichat
def zamichat
  n = $indexy.length
  pul = (n/2).floor.to_i
  0.step(pul,2) do
    |i|
    if i + pul >= n then break end
    pom = $indexy[i]
    $indexy[i] = $indexy[i+pul]
    $indexy[i+pul] = pom
  end
end

# premisti iword ze zacatku nakonec pole $indexy
def move2end
  iword = $indexy[0]
  $indexy.delete_at(0)
  $indexy.push(iword)
end

# naplneni pole $indexy
def start_iw
  $indexy.clear
  $words.each_index do
    |iword|
    word = $words[iword]
    if ($fname == '*' or word.fname == $fname) and word.level == $level
      $indexy << iword
    end
  end
  nindexy = $indexy.length
  if nindexy == 0
    return -1   # prazdne pole pro zkouseni
  else
    zamichat
    $iindexy = rand(nindexy)
    case $alg
      when 1
        return $indexy[$iindexy]
      when 2
        for ii in 0 ... $iindexy do move2end end
        return $indexy[0]
      else
        raise "Algorithm #{$alg} illegal value"
    end
  end
end

# nacteni dalsiho iw
def get_iw(kod)
  case $alg
    when 1                                  # nahodny vyber
      if kod == 'n'                         # neni nutno obnovovat $indexy
        $iindexy += 1
        if $iindexy == $indexy.length then $iindexy = 0 end
        return $indexy[$iindexy]            # return iw
      else                                  # obnovuje se pole $indexy
        return start_iw
      end
    when 2                                  # postupny vyber
      if kod == 'n'
        move2end
        return $indexy[0]
      else   # kod d x y
        if $indexy.length == 1   # posledni slovo
          return -1
        else
          $indexy.delete_at(0)
          return $indexy[0]
        end
      end
    else
      raise "Algorithm #{$alg} illegal value"
  end
end

# nahrazeni znaku ve stringu s1 jinym znakem ve stringu s2 na stejne pozici
def replace(s1,s2,z1,z2)
  for i in 0 ... s1.length do
    if s1[i,1] == z1 then s2[i,1] = z2 end
  end
end

# konverze z CP1250 na CP852
def konverze s1
  s2 = String.new(s1)
  if WINDOWS == true and KONVERZE == true
    replace(s1,s2,"\xec","\xd8") # e s hackem
    replace(s1,s2,"\xe8","\x9f") # c s hackem
    replace(s1,s2,"\xf8","\xfd") # r s hackem

    replace(s1,s2,"\xcc","\xb7") # E s hackem
    replace(s1,s2,"\xc8","\xac") # C s hackem
    replace(s1,s2,"\xd8","\xfc") # R s hackem

    replace(s1,s2,"\xef","\xd4") # d s hackem
    replace(s1,s2,"\xf2","\xe5") # n s hackem
    replace(s1,s2,"\x9d","\x9c") # t s hackem

    replace(s1,s2,"\xcf","\xd2") # D s hackem
    replace(s1,s2,"\xd2","\xd5") # N s hackem
    replace(s1,s2,"\x8d","\x9b") # T s hackem

    replace(s1,s2,"\x9e","\xa7") # z s hackem
    replace(s1,s2,"\x9a","\xe7") # s s hackem

    replace(s1,s2,"\x8e","\xa6") # Z s hackem
    replace(s1,s2,"\x8a","\xe6") # S s hackem

    replace(s1,s2,"\xe1","\xa0") # a s carkou
    replace(s1,s2,"\xe9","\x82") # e s carkou
    replace(s1,s2,"\xed","\xa1") # i s carkou
    replace(s1,s2,"\xf3","\xa2") # o s carkou
    replace(s1,s2,"\xfa","\xa3") # u s carkou
    replace(s1,s2,"\xfd","\xec") # y s carkou
    replace(s1,s2,"\xf9","\x85") # u s krouzkem

    replace(s1,s2,"\xc1","\xb5") # A s carkou
    replace(s1,s2,"\xc9","\x90") # E s carkou
    replace(s1,s2,"\xcd","\xd6") # I s carkou
    replace(s1,s2,"\xd3","\xe0") # O s carkou
    replace(s1,s2,"\xda","\xe9") # U s carkou
    replace(s1,s2,"\xdd","\xed") # Y s carkou
    replace(s1,s2,"\xd9","\xde") # U s kroužkem
  end
  return s2
end

# oprava
def oprava(iw)
  print "\nCorrection ["+$words[iw].english+']: '
  $stdout.flush
  vstup = gets.chomp
  if vstup != ''
    $words[iw].english = vstup
  end
  print 'Correction ['+$words[iw].czech+']: '
  $stdout.flush
  vstup = gets.chomp
  if vstup != ''
    $words[iw].czech = vstup
  end
  puts
    $stdout.flush
end

# zkouseni
def zkouseni
  iw = start_iw
  pocet_y = 0 # pocet spravne odpovezenych slovicek
  pocet_n = 0 # pocet nespravne odpovezenych slovicek
  if (iw == -1)
    puts "\nNo phrases to learn in "+$level.to_s+".level (see fraze.ini)\n\n"
    return false
  end
  while true do
    w = konverze($words[iw].word1)
    print w + ' '
    $stdout.flush
    kod = gets.chomp.downcase
    if kod =~ /[sclrx]/
    elsif kod == 'n'
      w = konverze($words[iw].word2)
      print '    ' + w
      $stdout.flush
      gets
    elsif kod !~ /[yq]/
      w = konverze($words[iw].word2)
      print '    ' + w + ' : '
      $stdout.flush
      while true
        kod = gets.chomp.downcase
        if kod =~ /[ynrclsxq]/
          break
        end
        puts 'y ... I know',
             'n ... I don\'t know',
             'r ... reset level (=0)',
             'c ... correction',
             'l ... learned phrases',
             's ... statistics',
             'x ... level + 3',
             'q ... quit'
        puts '****error - code outside yrclsxq'
        print ': '
        $stdout.flush
      end
    end

    if kod == 'q'
      break
    elsif kod == 'c'
      oprava(iw)
      next
    elsif kod == 'l'
      print 'Y=' + pocet_y.to_s + ' N=' + pocet_n.to_s
      printf(" 1:%.1f",pocet_n.to_f/pocet_y.to_f) if pocet_y > 0
      puts
      next
    elsif kod == 's'
      statistics
      next
    elsif kod =~ /[yrx]/
      change_level(kod,iw)
    end
    iw = get_iw(kod)
    if (iw == -1)
      puts "\nHotovo :-)\n\n"
      return true
    end
    pocet_y += 1 if kod == 'y'
    pocet_n += 1 if kod == 'n'
  end
  return true
end

# zmena config souboru
def cfg_change
  print "Direction eng->czech Y/N   [#{$en_cz}]: "
  $stdout.flush
  vstup = gets.chomp.upcase
  if vstup =~ /[YN]/
    $en_cz = vstup
  elsif vstup != ''
    raise "Illegal input value"
  end
  print "Import filename or *       [#{$fname}]: "
  $stdout.flush
  vstup = gets.chomp.upcase
   if vstup != ''
    $fname = vstup
  end
  print "Words level 0 ... n        [#{$level.to_s}]: "
  $stdout.flush
  vstup = gets.chomp.upcase
   if vstup =~ /[0123456789]/
    $level = vstup.to_i
  elsif vstup != ''
    raise "Illegal input value"
  end
  print "1(random)/2(all new first) [#{$alg.to_s}]: "
  $stdout.flush
  vstup = gets.chomp.upcase
   if vstup =~ /[12]/
    $alg = vstup.to_i
  elsif vstup != ''
    raise "Illegal input value"
  end

  fd = File.new('fraze.ini',"w")
  printf(fd,"(direction en->cz = Y) %s\n",$en_cz)
  printf(fd,"(filename) %s\n",$fname)
  printf(fd,"(level) %d\n",$level)
  printf(fd,"(algorithm) %d\n",$alg)
  fd.close
end

# vypis statistiky
def statistics
  fnames = []
  $words.each { |word| fnames << word.fname }
  fnames.uniq!
  enst = []
  czst = []
  printf("Statistics:   ")
  maxst = 0
  $words.each do
    |word|
    if word.enlevel > maxst then maxst = word.enlevel end
    if word.czlevel > maxst then maxst = word.czlevel end
  end
  for i in 0 .. maxst do printf("%5d",i) end
  fnames.each_index do
    |ifn|
    enst.clear
    czst.clear
    for ilevel in 0 .. maxst do
      enst[ilevel] = 0
      czst[ilevel] = 0
      $words.each do
        |word|
        if word.fname != fnames[ifn] then next end
        if word.enlevel == ilevel then enst[ilevel] += 1 end
        if word.czlevel == ilevel then czst[ilevel] += 1 end
      end
    end
    printf("\n%-10s en ",fnames[ifn][0,10])
    max = 0
    maxst.downto(1) { |i| if enst[i] != 0 then max = i; break end }
    for ilevel in 0 .. max do printf("%5d",enst[ilevel]) end
    printf("\n           cz ")
    max = 0
    maxst.downto(1) { |i| if czst[i] != 0 then max = i; break end }
    for ilevel in 0 .. max do printf("%5d",czst[ilevel]) end
  end
  printf("\n\n")
end

#vynulovani vsech hodnot levelu
def reset_level
  print "Reset level eng->cz? Y/N: "
  $stdout.flush
  vstup = gets.chomp.downcase
  if vstup == 'y'
    $words.each { |word| word.enlevel = 0 }
    puts 'level eng->cz is reseted'
  end
  print "Reset level cz->eng? Y/N: "
  $stdout.flush
  vstup = gets.chomp.downcase
  if vstup == 'y'
    $words.each { |word| word.czlevel = 0 }
    puts 'level cz->eng is reseted'
  end
end

#ZACATEK PROGRAMU
begin
  puts "FRAZE v.2.0", "----------------------------"
  cfg_read
  $words = []
  $indexy = []
  if FileTest.exist?('fraze.dat') == true
    data_read
  else
    import
    data_write  # zapis dat do souboru
  end

  res = true
  while true
    cfg_puts if res == true
    statistics if res == true
    print '()Learning (I)mport (C)onfig (R)eset_level (Q)uit : '
    res = true
    $stdout.flush
    akce = gets.chomp.downcase
    case akce
      when ''
        res = zkouseni
        data_write if res == true # zapis dat do souboru
      when 'i'
        import
        data_write  # zapis dat do souboru
      when 'c'
        cfg_change
      when 'r'
        reset_level
        data_write  # zapis dat do souboru
      when 'q'
        break
    end
  end
rescue
  puts '++++++++++++++++++++++++++++'
  puts 'Error: ' + $!
else              # kdyz neni chyba
  puts '++++++++++++++++++++++++++++'
ensure
  $stdout.flush
  gets if WINDOWS == true
end


