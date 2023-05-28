package decor::tables::users;
use strict;
use Decor::Core::Methods;

sub on_recalc 
{
  my $rec = shift;

  check_unique_field_set( $rec, 'NAME' ); # if same user NAME exists
}

#########################################

sub on_insert 
{
  my $rec = shift;

}

#########################################

sub on_update 
{
  my $rec = shift;

}

#########################################

sub on_do_resetpwd 
{
  my $rec = shift;

  #$rec->return_file_text( $rec->form_gen_data( 'RESET_PWD', { TEMP_PWD => $user->{ 'TEMP_PWD' } } ), 'HTML' );
}

1;
