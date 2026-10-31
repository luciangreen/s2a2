% Inverting the flies network by hand. Unknown input facts are free choices.
{ bird(tweety); bird(pingu); penguin(tweety); penguin(pingu) }.
% hidden unit for flies(X) :- bird(X), \+ penguin(X): weights +1, -1, threshold 0.5
h(X) :- X = (tweety;pingu), #sum{ 1,b : bird(X); -1,p : penguin(X) } >= 1.
flies(X) :- h(X).                    % output = OR of its hidden units (threshold 0.5)
:- not flies(tweety).                % observed: flies(tweety) is true
:- flies(pingu).                     % observed: flies(pingu) is false
in(bird(X)) :- bird(X).  in(penguin(X)) :- penguin(X).
#show in/1.
