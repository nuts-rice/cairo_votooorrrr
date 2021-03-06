# Declare this file as a StarkNet contract and set the required
# builtins.
%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.signature import verify_ecdsa_signature

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
     result_recorder_address : felt):
    result_recorder.write(value=result_recorder_address)
    return()
end


# Define a storage variable.
@storage_var
func poll_owner_public_key(poll_id) -> (public_key : felt):
end

@storage_var
func registered_voters(poll_id : felt, voter_public_key : felt) -> (is_registered : felt):
end

@storage_var
func voting_state(poll_id: felt, answer: felt) -> (number_votes : felt):
end

@storage_var
func voter_state(poll_id: felt, voter_public_key : felt) -> (has_voted : felt):
end

@storage_var
func result_recorder() -> (contract_address : felt):
end


#these arguments are necessary for accessing storage variables, implicit builtins
@external
func init_poll{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}(
     poll_id : felt, public_key : felt):
    let (is_poll_id_taken) = poll_owner_public_key.read(poll_id=poll_id)
    assert is_poll_id_taken = 0

    poll_owner_public_key.write(poll_id=poll_id, value=public_key)
    return()
end


func register_voter{syscall_ptr: felt*, range_check_ptr, pedersen_ptr : HashBuiltin*,
     ecdsa_ptr : SignatureBuiltin*} (poll_id: felt, voter_public_key: felt, r : felt, s : felt):
     let (owner_public_key) = poll_owner_public_key.read(poll_id=poll_id)
     #verify that poll is init
     assert_not_zero(owner_public_key)

     #verify validity of signature
     let (message) = hash2{hash_ptr=pedersen_ptr}(x=poll_id, y=voter_public_key)
     verify_ecdsa_signature(
     message=message, public_key=owner_public_key, signature_r=r, signature_s=s)

     registered_voters.write(poll_id=poll_id, voter_public_key=voter_public_key, value = 1)
     return ()
end

func vote{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*, ecdsa_ptr : SignatureBuiltin*} (
     poll_id : felt, voter_public_key : felt, vote : felt, r : felt, s : felt):
     verify_vote(poll_id=poll_id, voter_public_key=voter_public_key, vote=vote, r=r, s=s)

     let (current_number_votes) = voting_state.read(poll_id=poll_id, answer=vote)
     voting_state.write(poll_id=poll_id, answer=vote, value=current_number_votes + 1)
     voter_state.write(poll_id=poll_id, voter_public_key=voter_public_key, value=1)

     return()
end

#'view' decorator to ensure state is not changed
@view
func get_voting_state{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}(
     poll_id : felt) -> (number_no_votes : felt, number_yes_votes : felt):

     let (number_no_votes) = voting_state.read(poll_id=poll_id, answer=0)
     let (number_yes_votes) = voting_state.read(poll_id=poll_id, answer=1)

     return (number_no_votes=number_no_votes, number_yes_votes=number_yes_votes)
end





#private helper funcs with no decorator

func verify_vote{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, ecdsa_ptr : SignatureBuiltin*, range_check_ptr}(
     poll_id : felt, voter_public_key : felt, vote : felt, r : felt, s : felt):

     assert(vote - 0) * ( vote - 1) = 0
     let (is_registered) = registered_voters.read(poll_id=poll_id, voter_public_key=voter_public_key)
     #verify votooorrrr is registered
     assert_not_zero(is_registered)

     #verify votoorrrr hasnt voted yet
     let (has_voted) = voter_state.read(poll_id=poll_id, voter_public_key=voter_public_key)
     assert has_voted = 0

     #verify the validity of signature
     let (message) = hash2{hash_ptr=pedersen_ptr}(x=poll_id, y=vote)
     verify_ecdsa_signature(
     message=message, public_key=voter_public_key, signature_r=r, signature_s=s)

     return()
end

@external
func finalize_poll{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}(
     poll_id : felt):
     alloc_locals
     let (local result_recorder_address) = result_recorder.read()
     local pedersen_ptr: HashBuiltin* = pedersen_ptr

     let (number_no_votes, number_yes_votes) = get_voting_state(poll_id=poll_id)

     local syscall_ptr : felt* = syscall_ptr
     local pedersen_ptr : HashBuiltin* = pedersen_ptr

     let(result) = is_le(number_no_votes, number_yes_votes)

     let result = (result * 'Yes') + ((1 - result) * 'No')

     let (result) = ResultRecorder.get_poll_result(result_recorder_address, poll_id)

     return()
end


#interfaces

@contract_interface
namespace ResultRecorder:
          func record(poll_id : felt, result : felt):
          end

        func get_poll_result(poll_id : felt) -> (result: felt):
             end
end
