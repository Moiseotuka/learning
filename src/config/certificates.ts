export type Signatory = {
  name: string;
  label: string;
};

export const certificateSignatories: {
  instructor: Signatory;
  director: Signatory;
} = {
  instructor: {
    name: "Jean Dubois",
    label: "Signature de l'Instructeur",
  },
  director: {
    name: "Clara Moreau",
    label: "Signature du Directeur de Formation",
  },
};
