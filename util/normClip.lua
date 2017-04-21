local VERYSMALL = 1e-20
return function (tensor, normMax)
    local norm = torch.norm(tensor)
    if norm > normMax then
        tensor:mul(normMax/(norm +VERYSMALL))
    end

end

