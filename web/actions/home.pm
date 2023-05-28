##############################################################################
##
##  LIT
##  2023 (c) Vladi Belperchinov-Shabanski "Cade"
##           <cade@noxrun.com>
##
##############################################################################
package decor::actions::home;
use strict;

use Data::Dumper;
use Data::Tools;
use Data::Tools::Time 1.31;

use Web::Reactor::HTML::Utils;
use Web::Reactor::HTML::Layout;

use Decor::Shared::Types;
use Decor::Web::HTML::Utils;
use Decor::Web::View;
use Decor::Web::Utils;


sub main
{
  my $reo = shift;

  return "<#welcome>" unless $reo->is_logged_in();

  my $core = $reo->de_connect();

  my $si = $reo->get_safe_input();    # safe input
  my $ui = $reo->get_user_input();    # user input
  my $ps = $reo->get_page_session();  # current page session
  my $us = $reo->get_user_session();  # logged user session

  my $button    = $reo->get_input_button();    # for submit active button
  my $button_id = $reo->get_input_button_id(); # active button ident

  my $text;

  if( $button eq 'OK' )
    {
    $text .= "<h3>Selected days:</h3>";
    my $days = $ui->{ "DAYS" };
    my @days = split /;/, $days;
    my %days;
    for( @days )
      {
      next unless /\S/;
      if( s/^-// )
        {
        delete $days{ $_ };
        }
      else
        {
        $days{ $_ }++;
        }  
      }
    for my $day ( sort { $a <=> $b } keys %days )
      {
      $text .= "<p>" . type_format( $day, 'DATE' );
      }
    }


  $text .= <<JSEND;
           <script type="text/javascript">

           function cal_td_click( el, input_id )
           {
             var input = document.getElementById( input_id );
             //alert(el.dataset.selected);
             if( el.dataset.selected == 1 )
               {
               el.dataset.selected = 0;
               el.classList.remove( "cal-m-green" );
               input.value += ";-" + el.dataset.jd;
               }
             else
               {
               //alert('123');
               el.dataset.selected = 1;
               el.classList.add( "cal-m-green" );
               input.value += ";" + el.dataset.jd;
               }  
           }
  
           </script>
JSEND

  # map "busy/not-available" leave dates
  my $busy = { map { type_revert( $_, { NAME => 'DATE', FMT => 'DMY' } ) => 1 } qw( 1.1.2023 3.3.2023 1.5.2023 6.5.2023 24.5.2023 6.9.2023 22.9.2023 1.11.2023 24.12.2023 25.12.2023 26.12.2023 1.1.2024 3.3.2024 1.5.2024 6.5.2024 24.5.2024 ) };

  my $cal_form = new Web::Reactor::HTML::Form( REO_REACTOR => $reo );
  $text .= $cal_form->begin( NAME => "cal_1" );
  my $input_id = $reo->create_uniq_id();
  $text .= $cal_form->input( NAME => "DAYS", ID => $input_id, SIZE => 92, MAXLEN => 2048 );
  my $form_id = $cal_form->get_id();

  $text .= "<p><h1>Leave timetable for next 360 days</h1>";
  $text .= "<div class=gantt>" . de_html_calendar_linear( get_local_julian_day(), get_local_julian_day() + 365, $busy, { ONCLICK => "cal_td_click(this,'$input_id')", ACTIVE_WEEKDAYS_ONLY => 1 } ) . "</div>";

  $text .= "<p><h1>Leave timetable for next 360 days</h1>";
  $text .= "<div class=gantt>" . de_html_calendar_yearbox( get_local_julian_day(), get_local_julian_day() + 365, $busy, { ONCLICK => "cal_td_click(this,'$input_id')", ACTIVE_WEEKDAYS_ONLY => 1 } ) . "</div>";

  $text .= $cal_form->button( NAME => 'OK', VALUE => "   SELECT DATES   " );

  return $text;
}



sub de_html_calendar_linear
{
  my $fr   = shift;
  my $to   = shift;
  my $busy = shift; # hashref with busy (n/a) days
  my $opt  = shift || {};
  
  my $text;
  
  $text .= "<table cellspacing=0 cellpadding=0 class=cal width=96%>\n";

  # begin header row

  $text .= "<tr><td class=cal-label>&nbsp;</td>\n";
  
  my $same;
  my $t = get_local_julian_day(); # today

  for my $c ( $fr .. $to )
    {
    my $w  = julian_date_get_dow( $c );
    my $cs = type_format( $c, { NAME => 'DATE' } );

    my $colspan = 1;
    if( $cs =~ /^(\d\d\d\d\.\d+)\.(\d+)/ )
      {
      if( $1 ne $same )
        {
        $same = $1;
        $cs = "<b>$1</b>";
        $colspan = julian_date_month_days( $c );
        if( $c == $fr )
          {
          $colspan -= $2 - 1;
          }
        elsif( $c + $colspan > $to )
          {
          $colspan = $to - $c + 1;
          }  
        }
      else
        {
        next;
        }  
      }
 
    my $thc = " cal-head"; # head class
    $text .= "<td class='cal $thc' colspan=$colspan>$cs</td>\n";
    }
  
  $text .= "</tr>\n";

  # end header row


  # begin calendar row

  $text .= "<tr><td class=gantt-label>***</td>\n";

  my $y = 'red';

  for my $c ( $fr .. $to )
    {
    my $cs = julian_date_get_day( $c );
    $cs = '0' . $cs if $cs < 10;
    $text .= __de_html_calendar_td( $c, $cs, $busy, $opt );
    }
  
  $text .= "</tr>\n";

  # end calendar row
  
  $text .= "</table>\n";
  
  return $text;
}


sub de_html_calendar_yearbox
{
  my $fr   = shift;
  my $to   = shift;
  my $busy = shift; # hashref with busy (n/a) days
  my $opt  = shift || {};

  hash_uc_ipl( $opt );
  
  my $text;

  my $t = get_local_julian_day(); # today
  
  $text .= "<table cellspacing=0 cellpadding=0 class=cal width=96%>\n";

  # begin calendar row

  my $y = 'red';

  my $same;
  for my $c ( $fr .. $to )
    {
    my $w  = julian_date_get_dow( $c );
    
    my $cs = type_format( $c, { NAME => 'DATE' } );

    if( $cs =~ /^(\d\d\d\d\.\d+)\.(\d+)/ )
      {
      if( $1 ne $same )
        {
        $text .= "</tr>\n" if $same;
        $text .= "<tr class=cal><td class=cal-label>$1</td>\n";
        $same = $1;
        $cs = $2;
        if( $c == $fr )
          {
          $text .= "<td class='cal'>&nbsp;</td>" for( 1 .. julian_date_get_day( $c ) + julian_date_get_dow( julian_date_goto_first_dom( $c ) - 1 ) );
          }
        else
          {
          $text .= "<td class='cal'>&nbsp;</td>" for( 1 .. $w );
          }  
        }
      else
        {
        $cs = $2;
        }  
      }

    $text .= __de_html_calendar_td( $c, $cs, $busy, $opt );
    }
  

  # end calendar row
  
  $text .= "</table>\n";
  
  return $text;
}

sub __de_html_calendar_td
{
  my $c    = shift; # current julian day
  my $cs   = shift; # current julian day visible text
  my $busy = shift; # hashref with busy (n/a) days
  my $opt  = shift || {};

  my $t = get_local_julian_day(); # today
  my $w = julian_date_get_dow( $c );
  
  my $tag_data;
  my $day_active = 1;

  my $tdc = " cal-empty";
  if( exists $busy->{ $c } )
    {
    $tdc  = " cal-m-red";
    $tag_data .= " data-busy=1 ";
    $day_active = 0;
    }
  elsif( $w == 6 or $w == 0 )
    {
    $tdc .= " cal-weekend";
    $tag_data .= " data-weekend=1 ";
    $day_active = 0 if $opt->{ 'ACTIVE_WEEKDAYS_ONLY' };
    }
  $tdc .= " cal-today"   if $c == $t;

  $tdc .= " cal-active" if $day_active;

  my $in = "&nbsp;&nbsp;";

  my $onclick = 'onclick="' . $opt->{ 'ONCLICK' } . '"' if $day_active and $opt->{ 'ONCLICK' };
  
  return "<td class='cal $tdc' $onclick data-jd=$c $tag_data>$cs</td>\n";
}

1;
