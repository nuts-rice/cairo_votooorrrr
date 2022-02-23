# Declare this file as a StarkNet contract and set the required
# builtins.
%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.signature import verify_ecdsa_signature

# Define a storage variable.
@storage_var
func poll_owner_public_key(poll_id) -> (public_key : felt):
end

@storage_var
func registered_voters(poll_id : felt, voter_public_key : felt) -> (is_registered : felt):
end

@storage_var
func voting_state(poll_id: felt, answer: state) -> (number_votes : felt):
end

@storage_var
func voter_state(poll_id: felt, voter_public_key : felt) -> (has_voted : felt):
end

@external
#these arguments are necessary for accessing storage variables, implicit builtins
func init_poll{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
     poll_id : felt, public_key : felt):
    let (is_poll_taken) = poll_owner_public_key.read(poll_id=poll_id)
    assert is_poll_id_taken = 0

    poll_owner_public_key.write(poll_id=poll_id, value=public_key)
    return()
end


# Increases the balance by the given amount.
@external
func increase_balance{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*,
        range_check_ptr}(amount : felt):
    let (res) = balance.read()
    balance.write(res + amount)
    return ()
end

# Returns the current balance.
@view
func get_balance{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*,
        range_check_ptr}() -> (res : felt):
    let (res) = balance.read()
    return (res)
end
